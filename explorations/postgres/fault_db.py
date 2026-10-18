#!/usr/bin/env python3
"""Drops Postgres connections under load and measures how each /db server recovers.

Each run sends 1,000 requests per second for 20 seconds, open-loop. At 5 seconds it either kills the
app's backends with pg_terminate_backend or restarts Postgres. A probe then requests /db every 20 ms
until it gets a 200, which gives the recovery time.

Usage: fault_db.py OUT_DIR
"""

import json
import pathlib
import signal
import subprocess
import sys
import threading
import time
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from bench_db import SERVERS, SERVER_CPUS, wait_port, oha  # noqa: E402

KILL = ["su", "postgres", "-c", "psql -qAt -d hello_world -c \"SELECT count(pg_terminate_backend(pid)) "
        "FROM pg_stat_activity WHERE usename = 'benchmarkdbuser'\""]
RESTART = ["sh", "-c", "taskset -c 2 pg_ctlcluster 16 main restart"]


def probe(url, start):
    while True:
        try:
            with urllib.request.urlopen(url, timeout=1) as r:
                if r.status == 200:
                    return time.time() - start
        except Exception:
            pass
        time.sleep(0.02)


def run(name, cmd, path, fault, port):
    proc = subprocess.Popen(["taskset", "-c", SERVER_CPUS, *cmd, str(port)],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        wait_port(port)
        url = f"http://127.0.0.1:{port}{path}"
        oha(url, 2)
        result = {}
        load = threading.Thread(target=lambda: result.update(raw=oha(url, 20, rate=1000)))
        load.start()
        time.sleep(5)
        start = time.time()
        subprocess.run(KILL if fault == "terminate" else RESTART, check=True, capture_output=True)
        recovery = probe(url, start)
        load.join()
        raw = result["raw"]
        codes = raw.get("statusCodeDistribution") or {}
        row = {
            "server": name, "fault": fault, "recovery_s": round(recovery, 3),
            "status": codes, "errors": raw.get("errorDistribution") or {},
            "max_ms": raw["summary"]["slowest"] * 1000,
            "p999_ms": raw["latencyPercentiles"]["p99.9"] * 1000,
        }
    finally:
        proc.send_signal(signal.SIGKILL)
        proc.wait()
    print(f"{name} {fault}: recovered in {row['recovery_s']} s, status {codes}, "
          f"max {row['max_ms']:.0f} ms", flush=True)
    return row


def main():
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    port = 18700
    for fault in ["terminate", "restart"]:
        for name in ["go-pgx", "lean-wire", "lean-libpq"]:
            cmd, path = SERVERS[name]
            rows.append(run(name, cmd, path, fault, port))
            port += 1
            time.sleep(2)
    (out / "faults.json").write_text(json.dumps(rows, indent=1))


if __name__ == "__main__":
    main()

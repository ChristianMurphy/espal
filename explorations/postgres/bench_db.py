#!/usr/bin/env python3
"""Benchmarks TechEmpower's /db for the Postgres spike and writes raw results.

Servers run on CPUs 0 and 1, Postgres on CPU 2 (pinned when the cluster starts) and oha on CPU 3.
The method matches the HTTP spike: a closed-loop run finds the peak, then open-loop runs with latency
correction measure 25, 50, 70, 90 and 200 percent of it.

Usage: bench_db.py OUT_DIR [--seconds N] [--repeats N] [--only NAME ...]
"""

import argparse
import json
import os
import pathlib
import signal
import socket
import subprocess
import time

HERE = pathlib.Path(__file__).resolve().parent
BIN = HERE / ".lake/build/bin"
SERVER_CPUS = "0,1"
LOAD_CPUS = "3"
CONNECTIONS = 64
LEVELS = [25, 50, 70, 90, 200]

SERVERS = {
    "go-pgx": ([str(HERE / ".lake/go-db")], "/db"),
    "lean-wire": ([str(BIN / "db-server"), "wire"], "/db"),
    "lean-libpq": ([str(BIN / "db-server"), "libpq"], "/db"),
    "lean-plaintext": ([str(BIN / "db-server"), "wire"], "/plaintext"),
}


def wait_port(port, timeout=20.0):
    end = time.time() + timeout
    while time.time() < end:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                return
        except OSError:
            time.sleep(0.05)
    raise RuntimeError(f"port {port} never opened")


def postgres_cpu_seconds():
    """Busy time of CPU 2, where Postgres runs alone."""
    for line in pathlib.Path("/proc/stat").read_text().splitlines():
        if line.startswith("cpu2 "):
            user, nice, system, idle, iowait, irq, softirq = map(int, line.split()[1:8])
            return (user + nice + system + irq + softirq) / os.sysconf("SC_CLK_TCK")
    raise RuntimeError("no cpu2 line in /proc/stat")


def cpu_seconds(pid):
    fields = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf("SC_CLK_TCK")


def oha(url, seconds, rate=None):
    cmd = ["taskset", "-c", LOAD_CPUS, "oha", "--no-tui", "--output-format", "json",
           "-z", f"{seconds}s", "-c", str(CONNECTIONS)]
    if rate:
        cmd += ["-q", str(int(rate)), "--latency-correction"]
    return json.loads(subprocess.run(cmd + [url], check=True, capture_output=True, text=True).stdout)


def measure(pid, url, seconds, rate=None):
    before, pg_before = cpu_seconds(pid), postgres_cpu_seconds()
    raw = oha(url, seconds, rate)
    used, pg_used = cpu_seconds(pid) - before, postgres_cpu_seconds() - pg_before
    codes = raw.get("statusCodeDistribution") or {}
    ok = int(codes.get("200", 0))
    lat = raw["latencyPercentiles"]
    return {
        "rate": rate,
        "rps": raw["summary"]["requestsPerSec"],
        "ok": ok,
        "non200": sum(int(v) for k, v in codes.items() if k != "200"),
        "p50_ms": (lat.get("p50") or 0) * 1000,
        "p99_ms": (lat.get("p99") or 0) * 1000,
        "p999_ms": (lat.get("p99.9") or 0) * 1000,
        "max_ms": (raw["summary"].get("slowest") or 0) * 1000,
        "cpu_us_per_ok": used / ok * 1e6 if ok else None,
        "pg_cpu_us_per_ok": pg_used / ok * 1e6 if ok else None,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=pathlib.Path)
    ap.add_argument("--seconds", type=int, default=10)
    ap.add_argument("--repeats", type=int, default=3)
    ap.add_argument("--only", nargs="*")
    args = ap.parse_args()
    raw_dir = args.out / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    port = 18600
    for name, (cmd, path) in SERVERS.items():
        if args.only and name not in args.only:
            continue
        proc = subprocess.Popen(["taskset", "-c", SERVER_CPUS, *cmd, str(port)],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            wait_port(port)
            url = f"http://127.0.0.1:{port}{path}"
            oha(url, 3)
            peak = measure(proc.pid, url, args.seconds)
            row = {"server": name, "path": path, "peak": peak, "levels": {}}
            for level in LEVELS:
                row["levels"][str(level)] = [measure(proc.pid, url, args.seconds, peak["rps"] * level / 100)
                                             for _ in range(args.repeats)]
        finally:
            proc.send_signal(signal.SIGKILL)
            proc.wait()
        (raw_dir / f"{name}.json").write_text(json.dumps(row, indent=1))
        mid = sorted(r["p99_ms"] for r in row["levels"]["70"])[args.repeats // 2]
        print(f"{name} {path}: peak {peak['rps']:.0f} req/s, cpu {peak['cpu_us_per_ok']:.0f} us/req, "
              f"pg {peak['pg_cpu_us_per_ok']:.0f} us/req, p99 at 70% {mid:.2f} ms, non-200 {peak['non200']}", flush=True)
        port += 1


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Repeats the closed-loop peak for two processes behind haproxy, to show run-to-run spread.

Usage: repeat_peaks.py OUT_DIR [--runs N] [--seconds N] [RUNTIME ...]

Each call appends its rows, with the time they started, to repeat-peaks.json.
"""

import argparse
import json
import os
import pathlib
import subprocess
import time

from bench import HERE, oha, start, stop, wait_port
from bench_runtimes import RUNTIMES


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--seconds", type=int, default=10)
    ap.add_argument("runtimes", nargs="*", default=list(RUNTIMES))
    a = ap.parse_args()
    os.environ.setdefault("RUBY_BINDIR", "/opt/rbenv/versions/3.4.11/bin")
    out = pathlib.Path(a.out)
    rows = []
    for name in a.runtimes:
        started = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        procs, lines = [], []
        for i, cpus in enumerate(["0", "1"]):
            procs.append(start(RUNTIMES[name], 18401 + i, cpus=cpus))
            lines.append(f"  server s{i} 127.0.0.1:{18401 + i}")
        cfg = (HERE / "haproxy.cfg.in").read_text().replace("@FRONT@", "18410").replace("@SERVERS@", "\n".join(lines))
        cfg_path = out / f"haproxy-{name}.cfg"
        cfg_path.write_text(cfg)
        proxy = subprocess.Popen(["taskset", "-c", "2", "haproxy", "-f", str(cfg_path)],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            wait_port(18410)
            url = "http://127.0.0.1:18410/plaintext"
            oha(url, 3, cpus="3")
            peaks = [oha(url, a.seconds, cpus="3")["summary"]["requestsPerSec"] for _ in range(a.runs)]
        finally:
            for p in procs:
                stop(p)
            stop(proxy)
        rows.append({"runtime": name, "path": "/plaintext", "started": started, "peak_rps": peaks})
        print(f"{name:28} " + "  ".join(f"{p:8.0f}" for p in peaks), flush=True)
    results = out / "repeat-peaks.json"
    kept = json.loads(results.read_text()) if results.exists() else []
    results.write_text(json.dumps(kept + rows, indent=1))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Measures what lean-routing adds to a Std.Http request.

Each variant of router-serve runs pinned to CPU 0, with oha on CPU 3 and 64 connections. A
10-second closed-loop run gives the peak. A 10-second run at a fixed rate gives the server's CPU
time per request. Variants alternate within each round, so drift on a shared machine hits them
alike.

Usage: bench_router.py OUT_JSON [--rounds N] [--rate R]
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
SERVER = HERE / ".lake/build/bin/router-serve"
VARIANTS = ["bare", "table-2", "table-200", "router-200"]
PORT = 18600
URL = f"http://127.0.0.1:{PORT}/plaintext"


def wait_port(port, timeout=10.0):
    end = time.time() + timeout
    while time.time() < end:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                return
        except OSError:
            time.sleep(0.05)
    raise RuntimeError(f"port {port} never opened")


def cpu_seconds(pid):
    fields = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf("SC_CLK_TCK")


def oha(seconds, rate=None):
    cmd = ["taskset", "-c", "3", "oha", "--no-tui", "--output-format", "json", "-z", f"{seconds}s",
           "-c", "64"]
    if rate:
        cmd += ["-q", str(rate), "--latency-correction"]
    return json.loads(subprocess.run(cmd + [URL], check=True, capture_output=True, text=True).stdout)


def measure(variant, rate):
    proc = subprocess.Popen(["taskset", "-c", "0", str(SERVER), variant, str(PORT)],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        wait_port(PORT)
        oha(3)
        peak = oha(10)["summary"]["requestsPerSec"]
        before = cpu_seconds(proc.pid)
        fixed = oha(10, rate)
        used = cpu_seconds(proc.pid) - before
        ok = int((fixed.get("statusCodeDistribution") or {}).get("200", 0))
        return {"variant": variant, "peak_rps": peak, "cpu_us_per_request": used / ok * 1e6,
                "p99_ms_at_rate": fixed["latencyPercentiles"]["p99"] * 1000}
    finally:
        proc.send_signal(signal.SIGTERM)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--rounds", type=int, default=3)
    ap.add_argument("--rate", type=int, default=2000)
    a = ap.parse_args()
    rows = []
    for r in range(a.rounds):
        for v in VARIANTS:
            row = {"round": r + 1, **measure(v, a.rate)}
            rows.append(row)
            print(f"round {r + 1}  {v:11} peak {row['peak_rps']:7.0f}  cpu/request "
                  f"{row['cpu_us_per_request']:6.1f} µs  p99 {row['p99_ms_at_rate']:6.2f} ms", flush=True)
    pathlib.Path(a.out).write_text(json.dumps(rows, indent=1))


if __name__ == "__main__":
    main()

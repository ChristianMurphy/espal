#!/usr/bin/env python3
"""Compares one process spread over CPUs 0 and 1 with the same process pinned to CPU 0.

Usage: placement.py OUT_DIR [--seconds N] [RUNTIME ...]
"""

import argparse
import json
import os
import pathlib

from bench import oha, start, stop
from bench_runtimes import RUNTIMES


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--seconds", type=int, default=5)
    ap.add_argument("runtimes", nargs="*", default=list(RUNTIMES))
    a = ap.parse_args()
    os.environ.setdefault("RUBY_BINDIR", "/opt/rbenv/versions/3.4.11/bin")
    rows = []
    for name in a.runtimes:
        row = {"runtime": name, "path": "/plaintext"}
        for cpus in ["0,1", "0"]:
            proc = start(RUNTIMES[name], 18500, cpus=cpus)
            try:
                url = "http://127.0.0.1:18500/plaintext"
                oha(url, 2, cpus="3")
                row[f"cpus {cpus}"] = oha(url, a.seconds, cpus="3")["summary"]["requestsPerSec"]
            finally:
                stop(proc)
        rows.append(row)
        print(f"{name:28} CPUs 0,1 {row['cpus 0,1']:8.0f}  CPU 0 {row['cpus 0']:8.0f}", flush=True)
    (pathlib.Path(a.out) / "placement.json").write_text(json.dumps(rows, indent=1))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Measures how busy CPU 2 is while each Lean client runs four connections with 256 lookups in
flight. Postgres is pinned to CPU 2 and the clients to CPUs 0 and 1, so CPU 2's busy time is
Postgres's. The programs are named by SPIKE and ESPAL in the environment.
"""
import os
import re
import subprocess

CONNINFO = "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"
SECONDS = 5


def busy_ticks():
    for line in open("/proc/stat"):
        if line.startswith("cpu2 "):
            fields = [int(x) for x in line.split()[1:]]
            return sum(fields) - fields[3] - fields[4]
    raise SystemExit("no cpu2 line in /proc/stat")


hz = os.sysconf("SC_CLK_TCK")
env = dict(os.environ, ESPAL_BENCH_DATABASE=CONNINFO)
runs = [
    ("spike", [os.environ["SPIKE"], "libpq", "4", "256", str(SECONDS)]),
    ("espal", [os.environ["ESPAL"], "4", "256", str(SECONDS)]),
] * 3
for name, command in runs:
    before = busy_ticks()
    out = subprocess.run(["taskset", "-c", "0,1"] + command, capture_output=True, text=True, env=env).stdout
    after = busy_ticks()
    found = re.search(r"(\d+) queries in ([\d.]+)\s*s", out)
    queries, elapsed = int(found.group(1)), float(found.group(2))
    busy = (after - before) / hz
    print(f"{name}: {round(queries / elapsed)} q/s, CPU 2 busy {busy / elapsed * 100:.0f}%, "
          f"{busy / queries * 1e6:.1f} us of CPU 2 per query")

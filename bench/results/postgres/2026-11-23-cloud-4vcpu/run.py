#!/usr/bin/env python3
"""Runs the direct client benchmark in sets, and writes each run's output to raw/.

Each set runs both builds of `postgres-bench` once per shape, in an order that alternates from
set to set, so drift on a shared machine spreads over both. Compare builds within a set.

Usage: run.py SETS SECONDS, with Postgres pinned to CPU 2 beforehand. MAIN names the build
that sends the SQL text with each query, and PREPARED the build that prepares it once.
"""
import json
import os
import re
import resource
import subprocess
import sys

CONNINFO = "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"
SHAPES = [(1, 1), (1, 256), (4, 256)]
PROGRAMS = {"unprepared": "MAIN", "prepared": "PREPARED"}


def busy_ticks():
    for line in open("/proc/stat"):
        if line.startswith("cpu2 "):
            fields = [int(x) for x in line.split()[1:]]
            return sum(fields) - fields[3] - fields[4]
    raise SystemExit("no cpu2 line in /proc/stat")


def run(variant, conns, workers, seconds):
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    ticks = busy_ticks()
    env = dict(os.environ, ESPAL_BENCH_DATABASE=CONNINFO)
    done = subprocess.run(
        ["taskset", "-c", "0,1", os.environ[PROGRAMS[variant]], str(conns), str(workers), str(seconds)],
        capture_output=True, text=True, env=env, timeout=seconds + 60)
    busy = (busy_ticks() - ticks) / os.sysconf("SC_CLK_TCK")
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    cpu = (after.ru_utime - before.ru_utime) + (after.ru_stime - before.ru_stime)
    found = re.search(r"(\d+) queries in ([\d.]+)\s*s", done.stdout)
    if done.returncode != 0 or not found:
        raise SystemExit(f"{variant} {conns} {workers} failed: {done.stdout}{done.stderr}")
    queries, elapsed = int(found.group(1)), float(found.group(2))
    return {
        "variant": variant, "conns": conns, "workers": workers,
        "queries": queries, "seconds": elapsed,
        "queries_per_second": round(queries / elapsed),
        "client_cpu_us_per_query": round(cpu / queries * 1e6, 1),
        "postgres_cpu_percent": round(busy / elapsed * 100),
        "postgres_cpu_us_per_query": round(busy / queries * 1e6, 1),
        "output": done.stdout.strip(),
    }


def main():
    sets, seconds = int(sys.argv[1]), int(sys.argv[2])
    variants = ["unprepared", "prepared"]
    here = os.path.dirname(os.path.abspath(__file__))
    for index in range(sets):
        order = variants[index % 2:] + variants[:index % 2]
        results = []
        for conns, workers in SHAPES:
            for variant in order:
                result = run(variant, conns, workers, seconds)
                print(index + 1, result["variant"], conns, workers,
                      result["queries_per_second"], result["client_cpu_us_per_query"],
                      result["postgres_cpu_percent"], result["postgres_cpu_us_per_query"], flush=True)
                results.append(result)
        with open(os.path.join(here, "raw", f"set-{index + 1}.json"), "w") as out:
            json.dump(results, out, indent=2)
            out.write("\n")


main()

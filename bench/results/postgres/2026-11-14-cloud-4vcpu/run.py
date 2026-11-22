#!/usr/bin/env python3
"""Runs the direct client benchmark in sets, and writes each run's output to raw/.

Each set runs every variant once, in an order that rotates from set to set, so drift on a
shared machine spreads over the variants. Compare variants within a set.

Usage: run.py SETS SECONDS, with Postgres pinned to CPU 2 beforehand. The three programs are
named by BARE, SPIKE and ESPAL in the environment.
"""
import json
import os
import re
import resource
import subprocess
import sys

CONNINFO = "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"
SHAPES = [(1, 1), (1, 256), (4, 256)]


def command(variant, conns, workers, seconds):
    if variant == "bare":
        # The bare client takes queries in flight per connection.
        return [os.environ["BARE"], str(conns), str(max(1, workers // conns)), str(seconds)]
    if variant == "spike":
        return [os.environ["SPIKE"], "libpq", str(conns), str(workers), str(seconds)]
    return [os.environ["ESPAL"], str(conns), str(workers), str(seconds)]


def run(variant, conns, workers, seconds):
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    env = dict(os.environ, ESPAL_BENCH_DATABASE=CONNINFO)
    done = subprocess.run(
        ["taskset", "-c", "0,1"] + command(variant, conns, workers, seconds),
        capture_output=True, text=True, env=env, timeout=seconds + 60)
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
        "output": done.stdout.strip(),
    }


def main():
    sets, seconds = int(sys.argv[1]), int(sys.argv[2])
    variants = ["bare", "spike", "espal"]
    here = os.path.dirname(os.path.abspath(__file__))
    for index in range(sets):
        order = variants[index % 3:] + variants[:index % 3]
        results = []
        for conns, workers in SHAPES:
            for variant in order:
                result = run(variant, conns, workers, seconds)
                print(index + 1, result["variant"], conns, workers,
                      result["queries_per_second"], result["client_cpu_us_per_query"], flush=True)
                results.append(result)
        with open(os.path.join(here, "raw", f"set-{index + 1}.json"), "w") as out:
            json.dump(results, out, indent=2)
            out.write("\n")


main()

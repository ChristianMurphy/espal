#!/usr/bin/env python3
"""Turns the raw results from bench.py into Markdown tables, using the median of the repeats.

Usage: summarize.py RESULTS_DIR
"""

import json
import pathlib
import statistics
import sys


def median(runs, key):
    values = [r[key] for r in runs if r[key] is not None]
    return statistics.median(values) if values else None


def fmt(value, digits=1):
    return "–" if value is None else f"{value:,.{digits}f}"


def main():
    out = pathlib.Path(sys.argv[1])
    rows = [json.loads(p.read_text()) for p in sorted((out / "raw").glob("*.json"))]
    go = {r["path"]: r["peak"]["rps"] for r in rows if r["server"] == "go-net-http"}

    print("| Server | Path | Peak req/s | Share of Go | CPU µs per request at 70% | Peak RSS MiB |")
    print("|---|---|---|---|---|---|")
    for r in rows:
        share = r["peak"]["rps"] / go[r["path"]] if r["path"] in go else None
        cpu = median(r["levels"]["70"], "cpu_us_per_ok")
        rss = r["peak_rss_kib"] / 1024 if r["peak_rss_kib"] else None
        print(f"| {r['server']} | `{r['path']}` | {fmt(r['peak']['rps'], 0)} | "
              f"{'–' if share is None else f'{share:.1%}'} | {fmt(cpu)} | {fmt(rss)} |")

    print()
    print("| Server | Path | Load | p50 ms | p99 ms | p99.9 ms | Max ms | Non-200 |")
    print("|---|---|---|---|---|---|---|---|")
    for r in rows:
        for level, runs in r["levels"].items():
            non200 = sum(x["non200"] for x in runs)
            print(f"| {r['server']} | `{r['path']}` | {level}% | {fmt(median(runs, 'p50_ms'), 2)} | "
                  f"{fmt(median(runs, 'p99_ms'), 2)} | {fmt(median(runs, 'p999_ms'), 2)} | "
                  f"{fmt(median(runs, 'max_ms'), 1)} | {non200} |")

    proxy = out / "proxy.json"
    if proxy.exists():
        print()
        print("| Setup | Path | Peak req/s | p99 ms at 70% | p99.9 ms at 70% |")
        print("|---|---|---|---|---|")
        for r in json.loads(proxy.read_text()):
            mid = len(r["p99_ms_at_70"]) // 2
            print(f"| {r['setup']} | `{r['path']}` | {fmt(r['peak_rps'], 0)} | "
                  f"{fmt(r['p99_ms_at_70'][mid], 2)} | {fmt(r['p999_ms_at_70'][mid], 2)} |")


if __name__ == "__main__":
    main()

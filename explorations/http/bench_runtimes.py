#!/usr/bin/env python3
"""Compares Std.Http with Node.js, Ruby and Python on the HTTP spike's machine and method.

Each runtime runs as one process on CPUs 0 and 1, and as two processes pinned to one CPU each
behind haproxy on CPU 2. oha runs on CPU 3 in every setup. A closed-loop run finds the peak, then
three open-loop runs at 70 percent of it give p99 latency.

Usage: bench_runtimes.py OUT_DIR [--seconds N] [--repeats N] [RUNTIME ...]

Naming runtimes runs only those and replaces their rows in an existing runtimes.json.
"""

import argparse
import json
import os
import pathlib
import subprocess

from bench import HERE, B436, oha, start, stop, wait_port

RUNTIMES = {
    "std-http-small-4.36.0-rc1": [str(B436 / "spike-std-http-small")],
    "node-http": ["node", str(HERE / "node/server.js")],
    "ruby-puma": [str(HERE / "ruby/serve.sh"), "0"],
    "rails-puma": [str(HERE / "rails/serve.sh")],
    "flask-gunicorn": [str(HERE / "python/serve-flask.sh")],
    "fastapi-uvicorn": [str(HERE / "python/serve-fastapi.sh")],
}
GO = [str(HERE / ".lake/spike-go")]


def run(url, seconds, repeats):
    oha(url, 3, cpus="3")
    peak = oha(url, seconds, cpus="3")["summary"]["requestsPerSec"]
    runs = [oha(url, seconds, rate=peak * 0.7, cpus="3") for _ in range(repeats)]
    p99 = sorted(r["latencyPercentiles"]["p99"] * 1000 for r in runs)
    non200 = sum(int(v) for r in runs for k, v in (r.get("statusCodeDistribution") or {}).items() if k != "200")
    return {"peak_rps": peak, "p99_ms_at_70": p99, "non200_at_70": non200}


def setups(names):
    for name, cmd in RUNTIMES.items():
        if name in names:
            yield name, "one process, CPUs 0-1", cmd, None
            yield name, "two processes behind haproxy", cmd, ["0", "1"]
    if "go-net-http" in names:
        yield "go-net-http", "one process, CPUs 0-1", GO, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--seconds", type=int, default=10)
    ap.add_argument("--repeats", type=int, default=3)
    ap.add_argument("runtimes", nargs="*", default=[*RUNTIMES, "go-net-http"])
    a = ap.parse_args()
    os.environ.setdefault("RUBY_BINDIR", "/opt/rbenv/versions/3.4.11/bin")
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for name, setup, cmd, backends in setups(a.runtimes):
        for path in ["/plaintext", "/json"]:
            procs, proxy = [], None
            try:
                if backends is None:
                    procs.append(start(cmd, 18400))
                    url = f"http://127.0.0.1:18400{path}"
                else:
                    lines = []
                    for i, cpus in enumerate(backends):
                        procs.append(start(cmd, 18401 + i, cpus=cpus))
                        lines.append(f"  server s{i} 127.0.0.1:{18401 + i}")
                    cfg = (HERE / "haproxy.cfg.in").read_text().replace("@FRONT@", "18410").replace("@SERVERS@", "\n".join(lines))
                    cfg_path = out / f"haproxy-{name}.cfg"
                    cfg_path.write_text(cfg)
                    proxy = subprocess.Popen(["taskset", "-c", "2", "haproxy", "-f", str(cfg_path)],
                                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    wait_port(18410)
                    url = f"http://127.0.0.1:18410{path}"
                row = {"runtime": name, "setup": setup, "path": path, **run(url, a.seconds, a.repeats)}
            finally:
                for p in procs:
                    stop(p)
                if proxy:
                    stop(proxy)
            rows.append(row)
            print(f"{name:28} {setup:30} {path:10} peak {row['peak_rps']:8.0f}  p99@70 {row['p99_ms_at_70'][1]:7.2f} ms  non200 {row['non200_at_70']}", flush=True)
    results = out / "runtimes.json"
    kept = [r for r in json.loads(results.read_text()) if r["runtime"] not in a.runtimes] if results.exists() else []
    results.write_text(json.dumps(kept + rows, indent=1))


if __name__ == "__main__":
    main()

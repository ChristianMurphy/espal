#!/usr/bin/env python3
"""Runs the HTTP spike benchmarks and writes raw results and a summary.

The method follows the roadmap's benchmark section, shortened for a shared cloud machine:
open-loop load from oha at a fixed arrival rate with latency correction, a closed-loop run to
find the peak, then 25, 50, 70, 90 and 200 percent of that peak. Servers and the load generator
run on separate CPUs.

Usage: bench.py OUT_DIR [--seconds N] [--repeats N] [--only NAME ...]
"""

import argparse
import json
import os
import pathlib
import platform
import signal
import socket
import subprocess
import time

HERE = pathlib.Path(__file__).resolve().parent
B435 = HERE / ".lake/build/bin"
B436 = pathlib.Path(os.environ.get("SPIKE_436_BIN", HERE / "build436/.lake/build/bin"))
SERVER_CPUS = "0,1"
LOAD_CPUS = "2,3"
CONNECTIONS = 64
LEVELS = [25, 50, 70, 90, 200]

SERVERS = {
    "go-net-http": ([str(HERE / ".lake/spike-go")], ["/plaintext", "/json"]),
    "bare-async-4.35.0": ([str(B435 / "spike-bare-async")], ["/plaintext"]),
    "std-http-4.35.0": ([str(B435 / "spike-std-http")], ["/plaintext", "/json"]),
    "std-http-small-4.35.0": ([str(B435 / "spike-std-http-small")], ["/plaintext", "/json"]),
    "bare-async-4.36.0-rc1": ([str(B436 / "spike-bare-async")], ["/plaintext"]),
    "std-http-4.36.0-rc1": ([str(B436 / "spike-std-http")], ["/plaintext", "/json"]),
    "std-http-small-4.36.0-rc1": ([str(B436 / "spike-std-http-small")], ["/plaintext", "/json"]),
}


def wait_port(port, timeout=10.0):
    end = time.time() + timeout
    while time.time() < end:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                return
        except OSError:
            time.sleep(0.05)
    raise RuntimeError(f"port {port} never opened")


def start(cmd, port, cpus=SERVER_CPUS):
    proc = subprocess.Popen(["taskset", "-c", cpus, *cmd, str(port)],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    wait_port(port)
    return proc


def stop(proc):
    proc.send_signal(signal.SIGTERM)
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


def cpu_seconds(pid):
    fields = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf("SC_CLK_TCK")


def peak_rss_kib(pid):
    for line in pathlib.Path(f"/proc/{pid}/status").read_text().splitlines():
        if line.startswith("VmHWM:"):
            return int(line.split()[1])
    return None


def oha(url, seconds, rate=None, connections=CONNECTIONS, cpus=LOAD_CPUS):
    cmd = ["taskset", "-c", cpus, "oha", "--no-tui", "--output-format", "json",
           "-z", f"{seconds}s", "-c", str(connections)]
    if rate:
        cmd += ["-q", str(int(rate)), "--latency-correction"]
    out = subprocess.run(cmd + [url], check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def measure(pid, url, seconds, rate=None, **kw):
    before = cpu_seconds(pid)
    raw = oha(url, seconds, rate, **kw)
    used = cpu_seconds(pid) - before
    codes = raw.get("statusCodeDistribution") or {}
    ok = int(codes.get("200", 0))
    lat = raw["latencyPercentiles"]
    return {
        "rate": rate,
        "rps": raw["summary"]["requestsPerSec"],
        "ok": ok,
        "non200": sum(int(v) for k, v in codes.items() if k != "200"),
        "errors": raw.get("errorDistribution") or {},
        "p50_ms": (lat.get("p50") or 0) * 1000,
        "p99_ms": (lat.get("p99") or 0) * 1000,
        "p999_ms": (lat.get("p99.9") or 0) * 1000,
        "max_ms": (raw["summary"].get("slowest") or 0) * 1000,
        "cpu_us_per_ok": (used / ok * 1e6) if ok else None,
    }


def machine():
    lscpu = subprocess.run(["lscpu"], capture_output=True, text=True).stdout
    keep = ("Model name", "CPU(s)", "Thread(s) per core", "Hypervisor vendor", "L3 cache")
    return {
        "lscpu": [l.strip() for l in lscpu.splitlines() if l.split(":")[0].strip() in keep],
        "kernel": platform.release(),
        "memory": subprocess.run(["free", "-h"], capture_output=True, text=True).stdout.splitlines()[1],
        "go": subprocess.run(["go", "version"], capture_output=True, text=True).stdout.strip(),
        "oha": subprocess.run(["oha", "--version"], capture_output=True, text=True).stdout.strip(),
        "server_cpus": SERVER_CPUS,
        "load_cpus": LOAD_CPUS,
        "connections": CONNECTIONS,
    }


def run_server(name, cmd, paths, port, seconds, repeats, raw_dir):
    results = []
    for path in paths:
        proc = start(cmd, port)
        url = f"http://127.0.0.1:{port}{path}"
        try:
            oha(url, 3)
            peak = measure(proc.pid, url, seconds)
            row = {"server": name, "path": path, "peak": peak, "levels": {}}
            for level in LEVELS:
                runs = [measure(proc.pid, url, seconds, rate=peak["rps"] * level / 100)
                        for _ in range(repeats)]
                row["levels"][str(level)] = runs
            row["peak_rss_kib"] = peak_rss_kib(proc.pid)
        finally:
            stop(proc)
        (raw_dir / f"{name}{path.replace('/', '_')}.json").write_text(json.dumps(row, indent=1))
        results.append(row)
        print(f"{name} {path}: peak {peak['rps']:.0f} req/s, "
              f"p99 at 70% {sorted(r['p99_ms'] for r in row['levels']['70'])[len(row['levels']['70']) // 2]:.2f} ms",
              flush=True)
    return results


def tool_check(out):
    """Pauses the server for one second during an open-loop run; p99.9 must show the pause."""
    proc = start(SERVERS["go-net-http"][0], 18999)
    url = "http://127.0.0.1:18999/plaintext"
    try:
        oha(url, 2)
        timer = subprocess.Popen(["sh", "-c", f"sleep 4; kill -STOP {proc.pid}; sleep 1; kill -CONT {proc.pid}"])
        result = measure(proc.pid, url, 10, rate=20000)
        timer.wait()
    finally:
        stop(proc)
    result["passed"] = result["max_ms"] >= 900 and result["p999_ms"] >= 500
    (out / "tool-check.json").write_text(json.dumps(result, indent=1))
    print(f"tool check: p99.9 {result['p999_ms']:.0f} ms, max {result['max_ms']:.0f} ms, "
          f"passed={result['passed']}", flush=True)
    return result


def run_proxy(out, seconds, repeats, name="std-http-small-4.36.0-rc1"):
    """One process direct, one behind haproxy, and two behind haproxy, each process on its own CPUs."""
    cmd = SERVERS[name][0]
    results = []
    for label, backends in [("direct-1", None), ("haproxy-1", ["0,1"]), ("haproxy-2", ["0", "1"])]:
        for path in ["/plaintext", "/json"]:
            procs, proxy_proc = [], None
            try:
                if backends is None:
                    procs.append(start(cmd, 18300))
                    url = f"http://127.0.0.1:18300{path}"
                else:
                    lines = []
                    for i, cpus in enumerate(backends):
                        procs.append(start(cmd, 18301 + i, cpus=cpus))
                        lines.append(f"  server s{i} 127.0.0.1:{18301 + i}")
                    cfg = (HERE / "haproxy.cfg.in").read_text().replace("@FRONT@", "18310").replace("@SERVERS@", "\n".join(lines))
                    cfg_path = out / f"haproxy-{label}.cfg"
                    cfg_path.write_text(cfg)
                    proxy_proc = subprocess.Popen(["taskset", "-c", "2", "haproxy", "-f", str(cfg_path)],
                                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    wait_port(18310)
                    url = f"http://127.0.0.1:18310{path}"
                oha(url, 3, cpus="3")
                peak = oha(url, seconds, cpus="3")
                peak_rps = peak["summary"]["requestsPerSec"]
                runs = [oha(url, seconds, rate=peak_rps * 0.7, cpus="3") for _ in range(repeats)]
                row = {"setup": label, "path": path, "peak_rps": peak_rps,
                       "p99_ms_at_70": sorted(r["latencyPercentiles"]["p99"] * 1000 for r in runs),
                       "p999_ms_at_70": sorted(r["latencyPercentiles"]["p99.9"] * 1000 for r in runs)}
            finally:
                for proc in procs:
                    stop(proc)
                if proxy_proc:
                    stop(proxy_proc)
            results.append(row)
            print(f"{label} {path}: peak {peak_rps:.0f} req/s, p99 at 70% {row['p99_ms_at_70'][len(runs) // 2]:.2f} ms", flush=True)
    (out / "proxy.json").write_text(json.dumps(results, indent=1))
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=pathlib.Path)
    ap.add_argument("--seconds", type=int, default=10)
    ap.add_argument("--repeats", type=int, default=3)
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--proxy", action="store_true", help="run only the haproxy comparison")
    args = ap.parse_args()
    raw_dir = args.out / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    if args.proxy:
        run_proxy(args.out, args.seconds, args.repeats)
        return
    (args.out / "machine.json").write_text(json.dumps(machine(), indent=1))
    tool_check(args.out)
    port = 18100
    for name, (cmd, paths) in SERVERS.items():
        if args.only and name not in args.only:
            continue
        run_server(name, cmd, paths, port, args.seconds, args.repeats, raw_dir)
        port += 1


if __name__ == "__main__":
    main()

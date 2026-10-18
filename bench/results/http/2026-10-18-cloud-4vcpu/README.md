# HTTP spike results, 18 October 2026

These numbers come from the HTTP spike in the [spikes and a baseline](../../../../ROADMAP.md#spikes-and-a-baseline) milestone. The servers and the scripts live in `explorations/http` on the `explore/http` branch.

## Machine and method

The run used a shared cloud VM with 4 vCPUs, an Intel Xeon at 2.1 GHz under KVM. It had 15 GiB of memory and ran Linux 6.18. `machine.json` has the details. Servers ran on CPUs 0 and 1 and oha 1.16.0 ran on CPUs 2 and 3, with 64 connections.

The run follows the roadmap's [benchmark method](../../../../ROADMAP.md#benchmark-method) with shorter runs. A 10-second closed-loop run found each server's peak. Open-loop runs at a fixed arrival rate, with oha's latency correction, then measured 25, 50, 70, 90 and 200 percent of that peak. Each level ran three times for 10 seconds, and the tables show the median. The method asks for 60-second runs, five times each, on a dedicated machine. These figures guide the choice of server and stay out of any published claim.

Before the run, a tool check paused the Go server for one second under open-loop load. The pause showed up as 997 ms at p99.9 (`tool-check.json`), so the latency correction works.

## Servers

- `go-net-http`: Go 1.24.7 `net/http` with `encoding/json`, as its docs recommend.
- `bare-async`: a Std.Async loop that counts request ends and answers with fixed bytes. It parses nothing, so it marks the ceiling for any server on Lean's runtime.
- `std-http`: Std.Http, with `/json` built by `Lean.Data.Json` on every request.
- `std-http-small`: the same server with a small JSON encoder in place of `Lean.Data.Json`.

Each Lean server ran on Lean `4.35.0` and on `4.36.0-rc1`. By default, Std.Http closes a keep-alive connection after 100 requests, so the spike raised that limit.

## Results

| Server | Peak req/s, `/plaintext` | Share of Go | CPU per request at 70% | Peak memory |
|---|---|---|---|---|
| Go `net/http` | 94,452 | 100% | 19 µs | 14 MiB |
| Bare Std.Async, 4.36.0-rc1 | 27,535 | 29% | 53 µs | 65 MiB |
| Std.Http, 4.36.0-rc1 | 4,234 | 4.5% | 554 µs | 74 MiB |
| Std.Http small, 4.36.0-rc1 | 4,345 | 4.6% | 540 µs | 17 MiB |
| Std.Http, 4.35.0 | 900 | 1.0% | 1,677 µs | 143 MiB |

`/json` came out within a few percent of `/plaintext` for every server. `summary.md` has every server, path and load level, and `raw/` has each run.

- Lean 4.36.0-rc1 serves 4.7 times as many requests as 4.35.0 with Std.Http. The bare loop runs at the same speed on both, so the gain comes from the server fixes in 4.36.0-rc1.
- On 4.36.0-rc1, Std.Http spends ten times the CPU per request of the bare loop. That leaves room on this runtime for a server six times faster than Std.Http. Such a server would still reach only about a third of Go's speed.
- Latency stayed low until about 70 percent of peak for every server. At 70 percent, Std.Http's p99 was about 10 ms. At 200 percent, open-loop queues grew for the whole run and p99 reached seconds, as expected. No server returned an error status.
- Go's p99 at 70 percent was higher than Std.Http's, at 25 to 30 ms. At 66,000 requests per second, oha and Go compete for this small machine. For fast servers, latency here says more about the machine than the server.

## One process per core

`proxy.json` compares Std.Http small on 4.36.0-rc1 in three setups, with oha on CPU 3 and haproxy 2.8 on CPU 2.

| Setup | Peak req/s, `/plaintext` | Peak req/s, `/json` |
|---|---|---|
| One process on two CPUs, no proxy | 4,190 | 4,347 |
| One process on two CPUs, behind haproxy | 4,330 | 4,583 |
| Two processes on one CPU each, behind haproxy | 11,803 | 12,387 |

The proxy costs almost nothing at these rates. Two processes pinned to one CPU each serve 2.8 times as much as one process spread over the same two CPUs.

## Where the time goes

`profile/` holds a `perf` profile of Std.Http small at 3,000 requests per second, and context switch counts for three servers at that same rate.

| Server at 3,000 req/s | Context switches per request | CPU per request |
|---|---|---|
| Std.Http small, 4.36.0-rc1 | 26 | 544 µs |
| Bare Std.Async, 4.36.0-rc1 | 10 | 137 µs |
| Go `net/http` | 1.5 | 79 µs |

The kernel's scheduler takes 42 percent of Std.Http's samples. Allocation and reference counting take most of the rest, followed by the Lean task manager. Mutex calls take about 2 percent. Each step of an `Async` computation hands work to another thread, and those handoffs cost more than the HTTP parsing. That also explains the result above: a process pinned to one CPU has fewer cross-CPU handoffs.

## Other findings

- With `Lean.Data.Json`, the Std.Http binary is 120 MB and peaks at 74 MiB of memory. With the small encoder it is 7.7 MB and peaks at 17 MiB. The roadmap's binary target is under 10 MB, so Espal's JSON codec must not pull in `Lean.Data.Json`.
- Std.Http 4.35.0 writes the `Date` header as `Sun, 18 Oct 2026 17:03:38 +0000`. RFC 9110 requires `GMT` in place of `+0000`. 4.36.0-rc1 writes `GMT`.
- This machine has a time zone database, so 4.35.0's missing-response bug didn't appear here. The per-response read of that database still costs CPU on 4.35.0.

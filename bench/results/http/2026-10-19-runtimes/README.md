# HTTP runtimes compared, 19 October 2026

These numbers put Std.Http next to servers that web developers already use. They come from the same machine and method as the [HTTP spike results](../2026-10-18-cloud-4vcpu/README.md). The servers and the scripts live in `explorations/http` on the `explore/http` branch.

## Machine and method

The run used the HTTP spike's shared cloud VM. It has 4 vCPUs, an Intel Xeon at 2.1 GHz under KVM, and Linux 6.18. Each server ran in the two setups below.

- One process on CPUs 0 and 1.
- Two processes pinned to one CPU each, behind haproxy 2.8 on CPU 2.

The load generator, oha 1.16.0, ran on CPU 3 with 64 connections. In the main run, a 10-second closed-loop run found each server's peak. Three 10-second open-loop runs at 70 percent of that peak then measured p99 latency. `bench_runtimes.py` ran the main run and wrote `runtimes.json`.

`repeat_peaks.py` then measured the two-process `/plaintext` peak again, in sets of three runs, and kept every set in `repeat-peaks.json`. Std.Http ran six sets, FastAPI and Flask five, and the other servers two.

These are short runs on a shared machine. They show where Std.Http stands and stay out of published claims, as the [benchmark method](../../../../ROADMAP.md#benchmark-method) requires.

## Servers

Each server answers `/plaintext` and `/json` with the smallest app its documentation shows.

- Std.Http on Lean 4.36.0-rc1, with the spike's small JSON encoder.
- Node.js 22.22.0 with `node:http`.
- A bare Rack app on Puma 8.0.2 with five threads, on Ruby 3.4.11 with YJIT.
- Rails 8.1.4 in API mode and production mode, on the same Puma and Ruby.
- Flask 3.1.3 on gunicorn 26.2.0, one worker with eight threads, on Python 3.13.16.
- FastAPI 0.146.0 with `async def` handlers, on uvicorn 0.54.0 with uvloop and httptools, on Python 3.13.16.
- Go 1.24.7 `net/http`, which uses both CPUs from one process.

## Results

Most of these servers run in production as one process per core, so the two-process setup gives the fairest comparison. The table shows peak requests per second in that setup. Go ran as one process on both CPUs.

| Server | `/plaintext`, main run | `/plaintext`, repeat sets | `/json`, main run |
|---|---|---|---|
| Go `net/http` | 86,249 | not repeated | 82,982 |
| Node.js | 54,770 | 45,779 to 62,358 | 56,761 |
| Bare Rack on Puma | 37,594 | 27,981 to 48,415 | 33,313 |
| FastAPI on uvicorn | 14,113 | 11,600 to 14,412 | 11,747 |
| Std.Http, Lean 4.36.0-rc1 | 8,612 | 7,853 to 13,823 | 10,989 |
| Flask on gunicorn | 8,950 | 4,835 to 9,976 | 8,611 |
| Rails on Puma | 5,339 | 3,324 to 5,466 | 4,597 |

The comparisons below set servers side by side within each repeat set, since the machine's speed changed between sets.

- FastAPI served 1.4 to 1.7 times as many requests as Std.Http.
- Std.Http served 1.4 to 1.7 times as many as Flask, and about 2.5 times as many as Rails. In the main run it served about as many as Flask, 8,612 against 8,950.
- Node.js served 4.4 to 5.6 times as many requests as Std.Http in each set. Bare Rack on Puma served 3.2 to 3.5 times as many.
- In the main run, Go on two CPUs served 10 times as many requests as Std.Http.
- Peaks for one server varied by up to a factor of two between sets. Servers didn't drift together. Flask fell from about 9,800 to about 5,500, while FastAPI stayed between 11,600 and 14,400. Only large gaps rank servers on this machine.
- At 70 percent of peak, the median p99 ranged from 13 ms for Std.Http to 80 ms for bare Rack. At these rates haproxy and oha compete for the small machine, so the latencies say more about the machine than about the servers. `runtimes.json` has every p99.
- No server returned an error status.

A first FastAPI set used plain `def` handlers, which FastAPI runs on a thread pool. It gave 11,767 to 12,354. `repeat-peaks.json` keeps that set with a note.

### One process on two CPUs

| Server | `/plaintext` | `/json` |
|---|---|---|
| Go `net/http` | 86,249 | 82,982 |
| Node.js | 42,398 | 44,773 |
| Bare Rack on Puma | 10,410 | 10,768 |
| FastAPI on uvicorn | 6,729 | 5,674 |
| Std.Http, Lean 4.36.0-rc1 | 4,297 | 3,284 |
| Flask on gunicorn | 1,781 | 1,699 |
| Rails on Puma | 1,045 | 1,135 |

This setup understates the threaded Ruby and Python servers. `placement.py` ran each server as one process on CPUs 0 and 1, then pinned to CPU 0, for one 5-second run each. It wrote `placement.json`. It ran while the machine was slow, so compare the numbers within a row only.

| Server | CPUs 0 and 1 | CPU 0 alone |
|---|---|---|
| Node.js | 31,176 | 34,323 |
| Bare Rack on Puma | 6,450 | 13,078 |
| FastAPI on uvicorn | 6,646 | 5,970 |
| Std.Http, Lean 4.36.0-rc1 | 4,490 | 5,180 |
| Flask on gunicorn | 1,542 | 2,838 |
| Rails on Puma | 964 | 2,225 |

Pinning to one CPU about doubled Puma and gunicorn. Their threads take turns holding the interpreter lock, and handing it between two CPUs costs more than keeping it on one. Std.Http, FastAPI and Node.js changed by 15 percent or less.

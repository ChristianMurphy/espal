---
name: benchmarks
description: Run benchmarks for Espal, its spikes and its candidate dependencies, and report the results. Use when timing code, comparing servers or libraries, or writing up numbers.
---

# Benchmarks

## Running

- Pin the server and the load generator to separate CPUs with `taskset`, and record the machine.
- Write each baseline the way its own documentation recommends, such as FastAPI handlers with `async def`. A badly tuned baseline makes the comparison worthless.
- A shared VM drifts between runs. One server's peak varied by a factor of two in the runtime comparison. Repeat runs in sets, alternate the variants within each set, and compare variants only within a set.
- Check where the process runs. Threaded Ruby and Python servers ran about twice as fast pinned to one CPU as spread over two.
- Before timing alternatives, check that they give the same results on every kind of input the real code sees. The trie prototype checked `GET` routes only, and missed that it skipped a later route with the right method.
- Look over a prototype for avoidable work before ranking it. Skipping needless parsing moved the trie from nearly twice the index's time to within 0.1 µs of it.

## Reporting

- Commit the script and the raw output beside the write-up, and give medians with the range.
- Set each number beside the cost it competes with, such as router time against the 360 µs Std.Http spends on a request.
- After changing measured code, run the benchmark again, so the committed code is the code that produced the numbers.

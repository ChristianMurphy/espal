### Proposal

Let Std.Async wait until a socket that a C library owns becomes readable or writable.

Many C libraries built for event loops hand the host a socket and expect it to report readiness. Examples include libpq, libcurl's multi interface, c-ares and the MariaDB connector's async API. Std.Async can wait on sockets that Lean opened (`Std.Internal.UV.TCP.Socket.waitReadable`), but I couldn't find a way to wait on one from C.

**Why a binding can't add this itself.** As far as I can tell, the libuv loop and its lock are private to the runtime (`lean::global_ev` in `src/runtime/uv/event_loop.h`). The toolchain ships an empty `lean_libuv.h` and no libuv headers, so a binding can't call `uv_poll_init` on Lean's loop.

**The current workaround.** A dedicated task per connection blocks in `poll`. A C mutex keeps that task and the request handlers from using the connection at once. I measured it with libpq in pipeline mode on Lean 4.36.0-rc1, against Postgres 16 on one CPU:

| Client | One query in flight | Client CPU per query |
|---|---|---|
| libpq through a dedicated Lean task | 7,871 q/s | 102 µs |
| Bare C program using libpq | 15,627 q/s | 25.6 µs |

With four connections both reached the Postgres core's limit, so the cost shows up at low concurrency. The workaround also needs one OS thread per connection. Dedicated tasks blocked in `poll` keep the process alive after `main` returns, so programs must call `IO.Process.exit`.

**A possible shape.** This borrows the pattern TCP sockets already use, with a waiter, a way to cancel it, and a `Selector` built on both. A wait could then compose with `Selectable.one`, timers and cancellation.

```lean
namespace Std.Internal.UV.Poll
opaque new (socket : OsSocket) : IO Poll  -- an `int` on Unix, a `SOCKET` on Windows
opaque waitReadable (p : @& Poll) : IO (IO.Promise (Except IO.Error Bool))
opaque waitWritable (p : @& Poll) : IO (IO.Promise (Except IO.Error Bool))
opaque cancel (p : @& Poll) : IO Unit

namespace Std.Async.Poll
def readableSelector (p : Poll) : Selector Unit
def writableSelector (p : Poll) : Selector Unit
```

The names and types are placeholders. These are the semantics I have in mind, open to change:

- A wait is one-shot, like `waitReadable` on TCP. It resolves to `false` if cancelled.
- Readiness can be spurious, as libuv documents, so callers retry on `EAGAIN`.
- One `Poll` per socket, and the C library keeps ownership. The caller stops the `Poll` before the library closes the socket.
- On Windows, libuv polls only sockets. That seems enough for the libraries above, since each hands over a socket.

**Other ways to do this.**

- Keep a thread per connection. It works today, at the cost shown above.
- Write each protocol in Lean. The same spike has a pure-Lean Postgres client, with no TLS yet. With four connections it got about half of libpq's rate. All its I/O shares one event loop, which may explain the gap. This avoids C, but each library would need its own rewrite.
- Export the loop and its lock through `lean.h`. This gives bindings the most control. It would also tie them to how the runtime locks the loop, which is private today.

**Tests.** A socket pair could cover readable and writable readiness, cancelling a pending wait, stopping before close, and a `Selectable.one` race against a timer.

**Stability and who builds it.** For this use, an unstable `Std.Internal` API would be fine. #13469 mentions that runtime work isn't open to outside pull requests, so I'm filing this as a request. I'd be glad to test a branch or nightly against libpq and report the numbers.

**Open questions.** Would maintainers prefer this in Std.Async, or as a C function in `lean.h` that bindings call? Is there a reason to keep foreign sockets off the loop that I've missed?

- **User experience.** Bindings to these libraries could run inside Std.Async, with no thread per connection and no forced exit.
- **Beneficiaries.** Database drivers, HTTP clients built on libcurl, DNS through c-ares, and web frameworks such as [Espal](https://github.com/ChristianMurphy/espal).
- **Maintainability.** This would add one handle type on top of `uv_poll_t`, beside the TCP and UDP handles, following their waiter, cancel and `Selector` pattern.

Related: #13469 measures Std.Http's cost on the same runtime, and #8075 accepted exporting `lean.h` functions for bindings. The code and results are in [espal/bench/results/postgres](https://github.com/ChristianMurphy/espal/tree/main/bench/results/postgres/2026-10-18-cloud-4vcpu), with the binding in [`c/pq.c` on the explore/postgres branch](https://github.com/ChristianMurphy/espal/blob/explore/postgres/explorations/postgres/c/pq.c).

### Community Feedback

I asked on Zulip first, in [Waiting on a C library's socket in Std.Async](https://leanprover.zulipchat.com/#narrow/channel/270676-lean4/topic/Waiting.20on.20a.20C.20library.27s.20socket.20in.20Std.2EAsync/with/632829791).

<!-- Summarize the replies here before filing. -->

### Impact

Add :+1: to [issues you consider important](https://github.com/leanprover/lean4/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc). If others benefit from the changes in this proposal being added, please ask them to add :+1: to it.

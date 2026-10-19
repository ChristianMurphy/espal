### Proposal

Many C libraries built for event loops hand their host a socket and expect to hear when it's readable or writable. Examples include libpq, libcurl's multi interface, c-ares and the MariaDB connector's async API. Std.Async can wait on sockets that Lean opened, through `Std.Internal.UV.TCP.Socket.waitReadable`, but not on a socket that a C library opened.

As far as I can tell, a binding can't add this itself. The libuv loop and its lock are private to the runtime (`lean::global_ev` in `src/runtime/uv/event_loop.h`), and the toolchain ships no libuv headers. So a binding today runs a dedicated task per connection that blocks in `poll`. I measured it on Lean 4.36.0-rc1 with libpq in pipeline mode. With one query in flight, it runs at about half the rate of a bare C client.

| Client | Queries per second | Client CPU per query |
|---|---|---|
| libpq through a dedicated Lean task | 7,871 | 102 µs |
| Bare C program using libpq | 15,627 | 25.6 µs |

It also takes an OS thread per connection, and the blocked tasks keep the process alive after `main` returns, so programs end with `IO.Process.exit`. The [setup and raw numbers](https://github.com/ChristianMurphy/espal/tree/main/bench/results/postgres/2026-10-18-cloud-4vcpu) are public.

A few ways to do this:

1. **A poll handle in `Std.Internal.UV`.** libuv's `uv_poll_t` watches a socket it doesn't own. Lean could wrap it the way it wraps TCP, with a waiter, a way to cancel it and a `Selector`. A wait would then compose with `Selectable.one` and timers. Its docs would repeat libuv's caveats. Readiness can be spurious, and each socket can have only one handle. The handle has to stop before the socket closes, and on Windows it works only with sockets.
   ```lean
   namespace Std.Internal.UV.Poll
   opaque new (socket : OsSocket) : IO Poll  -- an `int` on Unix, a `SOCKET` on Windows
   opaque waitReadable (p : @& Poll) : IO (IO.Promise (Except IO.Error Bool))
   opaque waitWritable (p : @& Poll) : IO (IO.Promise (Except IO.Error Bool))
   opaque cancel (p : @& Poll) : IO Unit
   ```
2. **Export the loop and its lock through `lean.h`.** Bindings could call `uv_poll_init` themselves. That's more flexible, but it ties every binding to how the runtime locks the loop.
3. **Rewrite each protocol in Lean.** That avoids C, but each library needs its own rewrite, and Lean has no TLS yet.
4. **Keep the dedicated task.** No change to Lean, at the cost above.

The first seems the closest fit to how Std.Async works today, but I'd like to hear which, if any, would suit Lean. #13469 says runtime work isn't open to outside pull requests, so this is a request. I'd be glad to test a branch against libpq and report the numbers.

- **User experience.** Bindings to these libraries could run inside Std.Async, with no thread per connection and no forced exit.
- **Beneficiaries.** Database drivers, HTTP clients built on libcurl, and DNS through c-ares.
- **Maintainability.** The first option adds one handle type that follows the TCP and UDP handles.

### Community Feedback

I asked first in [Waiting on a C library's socket in Std.Async](https://leanprover.zulipchat.com/#narrow/channel/270676-lean4/topic/Waiting.20on.20a.20C.20library.27s.20socket.20in.20Std.2EAsync). No one has pointed to an existing way to do this or suggested an alternative so far.

### Impact

Add :+1: to [issues you consider important](https://github.com/leanprover/lean4/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc). If others benefit from the changes in this proposal being added, please ask them to add :+1: to it.

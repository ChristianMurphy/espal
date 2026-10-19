Closes #9.

A `MountPoint` now refuses an empty segment, as it already refuses `.` and `..`. So no mount root can give links that start with `//` and name another host.

- `MountPoint.valid` asks that no segment be `unlinkable`, the check a `String` capture already uses. `unlinkable` moves next to `dotSegment` in `Pattern.lean`.
- `MountPoint.ofSegs?` returns `none` for `[""]`, `["", "admin"]` and `["t", ""]`, and a literal root with an empty segment fails to compile. The tests pin both.
- `Route.prependLits` keeps its signature, and `MountPoint.noDotSegments` gives it the proof it takes.

This changes behaviour for code that builds such a root, which now gets `none` or a compile error. `route_table` and `mount_routes` already rejected empty segments, so tables don't change.

Two ways to get a `//` link remain: a route written by hand as `.lit "" :: rest`, and a direct call to `mountLink` with `""`. `PathSeg.lit` needs `""` for a mounted index's trailing slash, so closing the first takes more care. If you'd like those closed too, I can follow up.

This merges with #10 without conflicts. With #11 and #12, it conflicts only in the changelog's `[Unreleased]` section and next to `parseNat?`. All four pass `lake test` together.

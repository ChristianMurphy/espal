A small check in `MountPoint` would keep every link lean-routing builds on the app's own host. Today a root can start with an empty segment, and the links under it then start with `//`. Browsers read `//host/path` as a link to another host.

Under a root of `[""]`, the value of a `String` capture becomes that host. Say an app mounts each tenant with `MountPoint.ofSegs? [slug]`, and one tenant's slug is empty. A user of that tenant who registers the name `evil.example` gets a profile link to `http://evil.example/` on the app's own pages.

```lean
#eval (MountPoint.ofSegs? ["", "admin"]).isSome  -- true
#eval mountLink ["", "admin"]  -- "//admin"
#eval linkFor (mountSegs [.lit ""] [.capture "user" .string]) "evil.example"  -- "//evil.example"
```

Such a root is easy to build by accident. `"/admin".splitOn "/"` gives `["", "admin"]`, and `pathSegments "/"` gives `[""]`. A router with an index mounted at `["", "admin"]` also answers a request for `//admin` with a 308 to `//admin/`. A browser follows that to `http://admin/`. I checked both links and the redirect in Chromium against `main` at 75d8bc3. `route_table` and `mount_routes` reject empty segments, so tables aren't affected.

One fix would be for `MountPoint` to reject an empty segment, as it rejects `.` and `..`. That also covers a root such as `["t", ""]`, whose links contain `//`. The docstring of `unlinkable` says many proxies collapse those. Code that passes `""` to `.mk` would stop compiling, and `ofSegs?` would return `none` for it. A route written by hand as `.lit "" :: rest` would still give a `//` link.

A note in the docstring of `MountPoint` would be the smaller change. It leaves existing code compiling, but an app could still build such a root.

Would rejecting empty segments in `MountPoint` be a good fit? If so, I could open a pull request with tests and see it through review.

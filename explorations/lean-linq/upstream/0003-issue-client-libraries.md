The lakefile looks up libsqlite3, libpq, libsybdb and libmysqlclient when Lake loads it, and stops with an error if any of them is missing. A project that only uses Postgres, for example, has to install FreeTDS and the MySQL client before Lake will load lean-linq. The link settings also stay inside lean-linq's package. A program in another package that imports `LeanLinq.Driver.Postgres` fails to link with undefined `PQ*` symbols until that package adds libpq itself.

Two options come to mind:

1. **Skip libraries the lookup doesn't find.** This keeps the current layout and lets Lake load lean-linq with any subset of the client libraries installed. The test programs in lean-linq for a missing driver would then fail at link time instead. Other packages would still add libpq and the rest to their own link settings.
2. **Give each driver its own `lean_lib`.** Each one would name its client library in `moreLinkObjs`, through a `target` that looks the library up only when a program links against it. Lake collects `moreLinkObjs` from every library a program imports, including libraries in other packages. A program would then link the client libraries of the drivers it uses, with no settings of its own. The cost is a larger lakefile, with five libraries in place of one. Some system libraries, such as SQLite on Ubuntu 24.04, also need `-Wl,--allow-shlib-undefined` because they use newer glibc symbols than Lean's own glibc. Lake doesn't pass link arguments to other packages, so programs that use those drivers would still add that flag.

I prototyped the second option on Linux. A program in another package linked libpq with no settings of its own, and Lake loaded lean-linq with FreeTDS uninstalled.

Would either option be a good fit for lean-linq? I'd keep the macOS lookups as they are, and I'm glad to open a pull request in whichever shape suits you.

The lakefile looks up libsqlite3, libpq, libsybdb and libmysqlclient when Lake loads it, and stops with an error if any of them is missing. A project that only uses Postgres, for example, has to install FreeTDS and the MySQL client before Lake will load lean-linq.

The link arguments also stay inside lean-linq's package. An executable in a dependent package that imports `LeanLinq.Driver.Postgres` gets `libpq_shim`, but the link fails with undefined `PQ*` symbols until the dependent adds libpq to its own `moreLinkArgs`.

Would you be open to changing how the lakefile handles these? For the first part, the lakefile could fall back to `-lpq` and the like when it doesn't find a library, instead of stopping. I'm less sure of the right fix for the second part and would follow your preference. I'd be glad to open a pull request for either.

#!/bin/sh
# Puma serving the bare Rack app, with YJIT on as recent Rails versions default to.
# RUBY_BINDIR picks the Ruby, which has to be built with YJIT. Usage: serve.sh WORKERS PORT
bindir="${RUBY_BINDIR:-$(ruby -e 'print RbConfig::CONFIG["bindir"]')}"
exec env RUBY_YJIT_ENABLE=1 "$bindir/puma" -q -e production -w "$1" -t 5:5 -b "tcp://127.0.0.1:$2" "$(dirname "$0")/config.ru"

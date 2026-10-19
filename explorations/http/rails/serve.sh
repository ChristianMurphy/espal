#!/bin/sh
# Rails 8 on Puma with five threads in one process, YJIT on. RUBY_BINDIR picks the Ruby.
# Usage: serve.sh PORT
bindir="${RUBY_BINDIR:-$(ruby -e 'print RbConfig::CONFIG["bindir"]')}"
exec env RUBY_YJIT_ENABLE=1 RAILS_ENV=production "$bindir/puma" -q -e production -t 5:5 -b "tcp://127.0.0.1:$1" "$(dirname "$0")/config.ru"

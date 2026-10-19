#!/bin/sh
# One gunicorn worker process with eight threads. Usage: serve-flask.sh PORT
cd "$(dirname "$0")"
exec .venv/bin/gunicorn --no-control-socket -k gthread -w 1 --threads 8 -b "127.0.0.1:$1" flask_app:app

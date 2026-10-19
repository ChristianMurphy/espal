#!/bin/sh
# One uvicorn process without the access log. Usage: serve-fastapi.sh PORT
cd "$(dirname "$0")"
exec .venv/bin/uvicorn --log-level warning --no-access-log --host 127.0.0.1 --port "$1" fastapi_app:app

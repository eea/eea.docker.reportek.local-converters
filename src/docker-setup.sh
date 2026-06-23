#!/bin/bash
set -euo pipefail

: "${LC_HOME:=/opt/local_converters}"
: "${PORT:=5000}"
: "${WORKERS:=2}"
: "${TIMEOUT:=300}"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

mkdir -p "$LC_HOME/var"

exec gunicorn \
  --bind "0.0.0.0:${PORT}" \
  --workers "${WORKERS}" \
  --timeout "${TIMEOUT}" \
  --pid "$LC_HOME/var/converters.pid" \
  web:app

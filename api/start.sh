#!/usr/bin/env bash

set -e
set -o pipefail

echo 'starting postgres'
docker-entrypoint.sh postgres 1>/dev/stdout 2>/dev/stderr &
sleep 1

echo 'waiting until postgres ready'
timeout 120 sh -c 'while ! pg_isready --host localhost --user postgres --dbname gis --port 5432; do sleep 1; done'

echo 'starting api'
exec python3 -m api

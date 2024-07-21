#!/usr/bin/env bash

set -e
set -o pipefail

echo 'starting postgres'
# Optimized for low memory usage (150MB), see https://pgtune.leopard.in.ua/#/
docker-entrypoint.sh postgres \
  -c max_connections=200 \
  -c shared_buffers=38400kB \
  -c effective_cache_size=115200kB \
  -c maintenance_work_mem=9600kB \
  -c checkpoint_completion_target=0.9 \
  -c wal_buffers=1152kB \
  -c default_statistics_target=100 \
  -c random_page_cost=1.1 \
  -c effective_io_concurrency=200 \
  -c work_mem=96kB \
  -c huge_pages=off \
  -c min_wal_size=1GB \
  -c max_wal_size=4GB \
  1>/dev/stdout \
  2>/dev/stderr \
  &

echo 'waiting until postgres ready'
timeout 120 sh -c 'while ! pg_isready --host localhost --user postgres --dbname gis --port 5432; do sleep 1; done'

echo 'starting API'
exec fastapi run api.py --port "$PORT"

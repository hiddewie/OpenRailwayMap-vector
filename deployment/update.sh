#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

docker compose pull db
docker compose build martin
docker compose build martin-proxy
api/prepare-api.sh

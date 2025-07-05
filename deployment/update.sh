#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

docker compose pull db
docker compose build martin
docker compose build --build-arg "PRESET_VERSION=$(/bin/date -u "+1.%Y%m%d-%Y-%m-%d")" martin-proxy
docker compose build api

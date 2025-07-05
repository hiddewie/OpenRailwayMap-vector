#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

docker compose up db martin api
docker compose up --force-recreate --no-deps martin-proxy

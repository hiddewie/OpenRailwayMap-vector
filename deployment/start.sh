#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

exec docker compose up --no-build --no-pull db martin martin-proxy api

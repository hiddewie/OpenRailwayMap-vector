#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

exec docker compose up --no-build --no-deps db martin api proxy

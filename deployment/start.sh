#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

exec docker compose up --no-deps db martin api proxy

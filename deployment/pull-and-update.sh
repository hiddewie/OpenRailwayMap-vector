#!/usr/bin/env bash

cd /home/openrailwaymap/OpenRailwayMap-vector

git pull

exec deployment/update.sh

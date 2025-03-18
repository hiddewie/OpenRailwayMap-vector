# Deployment

This document describes how the OpenRailwayMap is deployed to https://openrailwaymap.fly.dev using [Github Actions](https://docs.github.com/en/actions) and [`fly.io`](https://fly.io/).

## Automatic deployment

The deployment is based on two steps:
- updating the OpenStreetMap data.
- using the data to generate tiles and deploy the OpenRailwayMap.

The data is stored in a Docker image in the [`openrailwaymap-data` package](https://github.com/hiddewie/OpenRailwayMap-vector/pkgs/container/openrailwaymap-data). Every night, the [nightly data update](./.github/workflows/nightly-update.yml) is triggered. In the workflow, the data is pulled and then updated using `pyosmium-up-to-date` (part of [PyOsmium](https://osmcode.org/pyosmium/)) from the OpenStreetMap changesets since the last update. The data is filtered to ensure the image stays small, and contains only objects with relevant tags to OpenRailwayMap. After the update, the data is pushed back into the package. 

After the data update, the [deployment workflow](./.github/workflows/deploy.yml) is triggered automatically. The workflow:
- uses the data to generate a PostgreSQL database optimized for the search API, and then deploys the search API
- uses the data to generate tiles for the planet. The tile generation is split per region (Africa, Asia, Europe, North America, Oceania and South America) for the high zoom levels, and separately for the low zoom levels. Per region, the tiles are deployed into a separate fly\.io application.
- deploys the proxy

## Manual deployment

Import the data:
```shell
docker compose run --build import import
```

Build the tiles:
```shell
docker compose run -e BBOX='-11.3818,35.8891,25.0488,70.0' martin-cp
```

Build and deploy the tile server:
```shell
flyctl deploy --config martin-static.fly.toml --local-only
```

Build and deploy the API:
```shell
api/prepare-api.sh
flyctl deploy --config api.fly.toml --local-only api
```

Build and deploy the caching proxy:
```shell
flyctl deploy --config proxy.fly.toml --local-only
```

The OpenRailwayMap is now available on https://openrailwaymap.fly.dev.

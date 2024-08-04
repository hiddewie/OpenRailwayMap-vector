# Setup

## Fetching data

Download an OpenStreetMap data file, for example from https://download.geofabrik.de/europe.html. Store the file as `data/data.osm.pbf` (you can customize the filename with `OSM2PGSQL_DATAFILE`).

## Development

Import the data:
```shell
docker compose run --build import import
```
The import process will filter the file before importing it. The filtered file will be stored in the `data/filtered` directory, so future imports of the same data file can reuse the filtered data file.

Start the tile server:
```shell
docker compose up --build martin
```

Prepare and start the API:
```shell
api/prepare-api.sh
docker compose up api
```

Start the web server:
```shell
docker compose up --build martin-proxy
```

The OpenRailwayMap is now available on http://localhost:8000.

To ease development, Docker Compose can automatically rebuild containers when dependent files change. Enable *watch mode* with:
```shell
docker compose watch
```

## Deployment

Import the data:
```shell
docker compose run --build import import
```

Build the tiles:
```shell
export BBOX='-11.3818,35.8891,25.0488,70.0'
for tile in low-med high standard speed signals electrification; do
    env "TILES=$tile" docker compose up martin-cp
done
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

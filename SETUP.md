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

Start the web server:
```shell
docker compose up --build martin-proxy
```

The OpenRailwayMap is now available on http://localhost:8000.

## Deployment

Import the data:
```shell
docker compose up --build import
```

Build the tiles:
```shell
docker compose up --build martin-cp
```

Build and deploy the tile server:
```shell
flyctl deploy --config martin-static.fly.toml --local-only
```

Build and deploy the caching proxy:
```shell
flyctl deploy --config proxy.fly.toml --local-only
```

The OpenRailwayMap is now available on https://openrailwaymap.fly.dev.

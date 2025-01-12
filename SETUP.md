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
docker compose up --build --watch martin
```

Prepare and start the API:
```shell
api/prepare-api.sh
docker compose up api
```

Start the web server:
```shell
docker compose up --build --watch martin-proxy
```

The OpenRailwayMap is now available on http://localhost:8000.

Docker Compose will automatically rebuild and restart the `martin` and `martin-proxy` containers if relevant files are modified.

### Making changes

If changes are made to features, the materialized views in the database have to be refreshed:
```shell
docker compose run --build import refresh
```

## Deployment

The process below imports a large OSM dataset by splitting and filtering it into smaller files for efficient and parallel tile rendering.

Ensure the OSM data is available in `data/data.osm.pbf`.

Define the bounding boxes of the deployment:
```shell
export 'BBOXES=3,50,4,54 4,50,5,54 5,50,6,54 6,50,7,54'
```

Filter and split the data:
```shell
docker compose run --build --entrypoint ./extract.sh -e BBOXES import
```

Optionally, build and push the data Docker images:
```shell
mv .dockerignore .dockerignore.bak
echo '**' > .dockerignore
echo '!data/data.osm.pbf' >> .dockerignore
for bbox in $BBOXES; do
  cp "data/split/$bbox/data.osm.pbf" data/data.osm.pbf
  docker build --push -f data/data.Dockerfile -t "ghcr.io/hiddewie/openrailwaymap-data:$(echo "$bbox" | sed 's/,/_/g')" data
done
rm -f data/data.osm.pbf
mv .dockerignore.bak .dockerignore
```

Optionally, update the data:
```shell
for bbox in $BBOXES; do
  docker compose run --build --entrypoint ./update.sh -e "DATAFILE=split/$bbox/data.osm.pbf" -e "BBOX=$bbox" import
done
```

Generate tiles for each of the bounding box slices:
```shell
for bbox in $BBOXES; do
  docker compose run --build -e "OSM2PGSQL_DATAFILE=split/$bbox/data.osm.pbf" import import
  
  for tile in low-med high standard speed signals electrification; do
    docker compose run -e "BBOX=$bbox" -e "TILES=$tile" -e "TILES_DIR=$bbox" martin-cp
  done
  
  mkdir -p "tiles/$bbox"
  mv tiles/*.mbtiles "tiles/$bbox"
done
```

Merge generated tiles:
```shell
docker compose run --entrypoint /tiles/merge.sh -e BBOXES --no-deps martin-cp
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

## Tests

Tests use [*hurl*](https://hurl.dev/docs/installation.html).

Run tests against the API:

```shell
hurl --test --verbose --variable base_url=http://localhost:5000/api api/test/api.hurl
```

Run tests against the proxy:

```shell
hurl --test --verbose --variable base_url=http://localhost:8000 proxy/test/proxy.hurl
```

Run tests against the tiles:

```shell
hurl --test --verbose --variable base_url=http://localhost:3000 tiles/test/tiles.hurl
```

## Development

### Code generation

The YAML files in the `features` directory are templated into SQL and Lua code.

You can view the generated files:
```shell
docker build --target build-signals --tag build-signals --file import/Dockerfile . \
  && docker run --rm --entrypoint cat build-signals /build/signals_with_azimuth.sql | less

docker build --target build-lua --tag build-lua --file import/Dockerfile . \
  && docker run --rm --entrypoint cat build-lua /build/tags.lua | less

docker build --target build-styles --tag build-styles --file proxy.Dockerfile . \
  && docker run --rm --entrypoint ls build-styles

docker build --target build-styles --tag build-styles --file proxy.Dockerfile . \
  && docker run --rm --entrypoint cat build-styles standard.json | jq . | less
```

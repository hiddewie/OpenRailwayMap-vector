# Setup

## Fetching data

Download an OpenStreetMap data file, for example from https://download.geofabrik.de/europe.html. Store the file as `data/data.osm.pbf` (you can customize the filename with `OSM2PGSQL_DATAFILE`).

## Development

Ensure [Docker](https://docs.docker.com/engine/install/) or [Podman](https://podman.io/docs/installation) is installed. In case of Podman, replace `docker` with `podman` in the commands below.

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
docker compose up --build --watch api
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

### Updating the OSM data

The OSM data file can be updated with:
```shell
docker compose run --build import update
```
This command will request all updates in the region and process them into the OSM data file.

After updating the data, run a new import:
```shell
docker compose run --build import import
```

### JOSM preset

Download the generated JOSM preset on http://localhost:8000/preset.zip.

### Enabling SSL

SSL is supported by generating a trusted certificate, and installing it in the proxy.

- [Install mkcert](https://github.com/FiloSottile/mkcert?tab=readme-ov-file)
- Install the `mkcert` CA in the system:
  ```shell
  mkcert -install
  ```
- Restart your browser
- Run `mkcert` to generate certificates for `localhost`:
  ```shell
  mkcert localhost
  ```
- Create a file `compose.override.yaml` with 
  ```yaml
  services:
    martin-proxy:
      volumes:
        - './localhost.pem:/etc/nginx/ssl/certificate.pem'
        - './localhost-key.pem:/etc/nginx/ssl/key.pem'
  ```
- Restart the proxy with:
  ```shell
  docker compose up --build --watch martin-proxy
  ```

The OpenRailwayMap is available on https://localhost, with SSL enabled and without browser warnings. 

You can modify the TLS port 443 to port 8443 [in the Compose configuration](./compose.yaml), if you want the container to start without privileges, for example using Podman.

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

## Development

### Code generation

The YAML files in the `features` directory are templated into SQL and Lua code.

You can view the generated files:
```shell
docker build --target build-signals --tag build-signals --file import/Dockerfile . \
  && docker run --rm --entrypoint cat build-signals /build/signal_features.sql | less

docker build --target build-operators --tag build-operators --file import/Dockerfile . \
  && docker run --rm --entrypoint cat build-operators /build/operators.sql | less

docker build --target build-lua --tag build-lua --file import/Dockerfile . \
  && docker run --rm --entrypoint cat build-lua /build/tags.lua | less

docker build --target build-styles --tag build-styles --file proxy.Dockerfile . \
  && docker run --rm --entrypoint ls build-styles

docker build --target build-styles --tag build-styles --file proxy.Dockerfile . \
  && docker run --rm --entrypoint cat build-styles standard.json | jq . | less
```

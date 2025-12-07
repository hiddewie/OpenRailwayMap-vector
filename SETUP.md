# Setup

## Fetching data

Download an OpenStreetMap data file, for example from https://download.geofabrik.de/europe.html. Store the file as `data/data.osm.pbf` (you can customize the filename with `OSM2PGSQL_DATAFILE`).

## Development

Ensure [Docker](https://docs.docker.com/engine/install/) or [Podman](https://podman.io/docs/installation) is installed. In case of Podman, replace `docker` with `podman` in the commands below.

Start the services with:
```
docker compose up --build --watch
```

The command will start the database (service `db`), run the data import (service `import`), start the tile server Martin (service `martin`), start the API (service `api`) and the web server (service `proxy`). The import can take a few minutes depending on the amount of data to be imported.

Docker Compose will automatically rebuild and restart the `martin` and `proxy` containers if relevant files are modified.

The OpenRailwayMap is now available on http://localhost:8000.

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
    proxy:
      volumes:
        - './localhost.pem:/etc/nginx/ssl/certificate.pem'
        - './localhost-key.pem:/etc/nginx/ssl/key.pem'
  ```
- Restart the proxy with:
  ```shell
  docker compose up --build --watch proxy
  ```

The OpenRailwayMap is available on https://localhost, with SSL enabled and without browser warnings. 

You can modify the TLS port 443 to port 8443 [in the Compose configuration](./compose.yaml), if you want the container to start without privileges, for example using Podman.

## Tests

### Import tests

The import tests verify the correctness of the Lua import configuration.

Run the tests with:
```shell
docker compose run --rm --build import-test
```

If the process exists successfully, the tests have succeeded. If not, the assertion error will be displayed.

### Tile tests

Tile tests use [*hurl*](https://hurl.dev/docs/installation.html).

Run tests against the API:
```shell
docker compose run --build --no-deps api-test
```

### Proxy tests

Proxy tests use [*hurl*](https://hurl.dev/docs/installation.html).

Run tests against the proxy:
```shell
docker compose run --build --no-deps proxy-test
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

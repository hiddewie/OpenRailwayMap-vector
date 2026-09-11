# Deployment

The OpenRailwayMap is deployed on a server to provide a database with OpenStreetMap data, render tiles using Martin and serve the tiles and static assets using an Nginx proxy.

## Requirements

- A server with root SSH access.

## Diagram

![](diagram.svg)

## Data import

An initial import of OSM data is required. After the initial data import, the daily update will ensure the data is kept up to date.

Download the OSM planet file:
```shell
deployment/download-planet.sh
```
This will download around 90GB.

Filter the OSM data, package it and push it to the container registry:
```shell
deployment/filter-and-package-planet.sh
```
This will process the planet OSM file, and output it into a Docker container. The filtering process takes time and a few GB of memory.

Optionally delete the source OSM data file to reduce disk space usage:
```shell
rm -f data/planet.osm.pbf
```

## Setup

### Docker

Install Docker (https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

Install APT repository
```shell
# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
```

Install Docker
```shell
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify Docker works
```shell
docker run hello-world
```

### JQ

Install JQ:
```shell
apt install jq
```

Verify JQ works:
```shell
echo '{}' | jq .
```

### User

Create new user `openrailwaymap` which has permission to access the Docker daemon:
```shell
useradd --create-home --groups users,docker --shell /bin/bash openrailwaymap
```
      
### Github deploy key

Generate deploy key with access to Github repository.

Use the `openrailwaymap` user:
```shell
su openrailwaymap
cd
```

Generate SSH key:
```shell
ssh-keygen -t ed25519 -C "openrailwaymap"
```

Add public key to Github repository, see https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#set-up-deploy-keys

Verify the SSH key works to access the repository, see https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection:
```shell
ssh -T git@github.com
```

Clone Github repository:
```shell
git clone git@github.com:hiddewie/OpenRailwayMap-vector.git
cd OpenRailwayMap-vector
```

### Github Packages

Use the `openrailwaymap` user:
```shell
su openrailwaymap
cd
```

Generate an access token that has read access to Github Packages:
  - No expiration
  - Scopes: `read:packages`

Log into Docker for the Github Docker registry
```shell
docker login ghcr.io -u hiddewie
```
(paste token as password)

Verify that pulling packages works:
```shell
docker compose pull db
```

### SSL

Use the `openrailwaymap` user:
```shell
su openrailwaymap
cd ~/OpenRailwayMap-vector
```

Ensure the SSL certificate and key are installed in `/etc/nginx/ssl`.

Create a file `compose.override.yaml`:
```yaml
services:
  db:
    image: ghcr.io/hiddewie/openrailwaymap-import-db:latest

  martin:
    image: ghcr.io/hiddewie/openrailwaymap-martin:latest

  api:
    image: ghcr.io/hiddewie/openrailwaymap-api:latest

  proxy:
    image: ghcr.io/hiddewie/openrailwaymap-proxy:latest
    build:
      args:
        PUBLIC_PROTOCOL: https
        PUBLIC_HOST: openrailwaymap.app
    environment:
      PUBLIC_PROTOCOL: https
      PUBLIC_HOST: openrailwaymap.app
      NGINX_CACHE_TTL: 86400
      CLIENT_CACHE_TTL_ASSETS_FRESH: 3600
      CLIENT_CACHE_TTL_ASSETS_STALE: 604800
      CLIENT_CACHE_TTL_API_FRESH: 8182
      CLIENT_CACHE_TTL_API_STALE: 604800
      CLIENT_CACHE_TTL_TILES_FRESH: 8182
      CLIENT_CACHE_TTL_TILES_STALE: 604800
    volumes:
      - '/etc/nginx/ssl/certificate.pem:/etc/nginx/ssl/certificate.pem'
      - '/etc/nginx/ssl/key.pem:/etc/nginx/ssl/key.pem'
```

### System service

Edit `/etc/systemd/system/openrailwaymap.service`:
```
[Unit]
Description=Run OpenRailwayMap
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=/home/openrailwaymap/OpenRailwayMap-vector/deployment/start.sh
User=openrailwaymap

[Install]
WantedBy=multi-user.target
```

Reload systemd:
```shell
systemctl daemon-reload
```

Enable and start the service:
```shell
systemctl enable openrailwaymap.service
systemctl start openrailwaymap.service
```

### Daily update

Install the daily update timer and service

Edit `/etc/systemd/system/update-openrailwaymap.timer`:
```
[Unit]
Description=Daily update OpenRailwayMap

[Timer]
OnCalendar=*-*-* 08:00:00 Europe/Amsterdam
Persistent=true

[Install]
WantedBy=timers.target
```

Edit `/etc/systemd/system/update-openrailwaymap.service`:
```
[Unit]
Description=Update OpenRailwayMap
OnSuccess=restart-openrailwaymap.service

[Service]
Type=oneshot
ExecStart=/home/openrailwaymap/OpenRailwayMap-vector/deployment/pull-and-update.sh
User=openrailwaymap
```

Edit `/etc/systemd/system/restart-openrailwaymap.service`:
```
[Unit]
Description=Restart OpenRailwayMap service

[Service]
Type=oneshot
ExecStart=systemctl restart openrailwaymap.service
```

Reload systemd:
```shell
systemctl daemon-reload
```

Enable the timer:
```shell
systemctl enable update-openrailwaymap.timer
```

Verify the timer is installed:
```shell
systemctl list-timers --all
```

Verify the timer works as intended:
```shell
systemctl start update-openrailwaymap.service
```

### Daily Docker cleanup

Edit `/etc/systemd/system/prune-docker.timer`:
```
[Unit]
Description=Daily Docker prune

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Edit `/etc/systemd/system/prune-docker.service`:
```
[Unit]
Description=Prune Docker

[Service]
Type=oneshot
ExecStart=docker system prune --force
```

Reload systemd:
```shell
systemctl daemon-reload
```

Enable the timer:
```shell
systemctl enable prune-docker.timer
```

Verify the timer is installed:
```shell
systemctl list-timers --all
```

Verify the timer works as intended:
```shell
systemctl start prune-docker.service
```

## Cloudflare

Configure Cloudflare to point to the IPv6 address of the server.

## Ready!

The OpenRailwayMap is now available on https://openrailwaymap.app.

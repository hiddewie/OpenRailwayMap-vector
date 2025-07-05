# Deployment

The OpenRailwayMap is deployed on a server to provide a database with OpenStreetMap data, render tiles using Martin and serve the tiles and static assets using an Nginx proxy.

## Requirements

- A server with root SSH access.

## Diagram

TODO

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

### Daily update

- Start everything
- ```shell
  git pull
  docker compose pull db
  docker compose up --no-build --wait --force-recreate db
  docker compose up --build --wait --no-deps --force-recreate martin
  docker compose up --build --wait --no-deps --force-recreate martin-proxy
  ```
- Install database
- Install proxy
- Install tiles
- Install cron to update daily
  - TODO
  - ```shell
    git clone git@github.com:hiddewie/OpenRailwayMap-vector.git
    
    docker compose up --pull --no-build
    ```

### Daily Docker cleanup

Configure the cronjob:
```shell
cd /etc/cron.daily
echo '#!/bin/bash' > /etc/cron.daily/docker-prune-daily
echo >> /etc/cron.daily/docker-prune-daily
echo 'docker system prune --force' >> /etc/cron.daily/docker-prune-daily
chmod +x /etc/cron.daily/docker-prune-daily
```
  
Verify the cronjob with:
```shell
run-parts /etc/cron.daily
```

### TODO

- configure client certificates

## Cloudflare

Configure Cloudflare to point to the IPv6 address of the server.

TODO:
- configure client certificates

## Ready!

The OpenRailwayMap is now available on https://openrailwaymap.app.

# OpenRailwayMap API

This is a reimplementation of the OpenRailwayMap API in Python with performance as main development goal.
Its public REST API is not exactly the same as the old PHP implementation but it should do the job good enough
it serves to the website www.openrailwaymap.org.

## Features

* Facility search
  * Search facilities (stations, halts, tram stops, yards, sidings, crossovers) including disused, abandoned,
    razed and proposed ones and those under construction by name or reference.
  * Fulltext search using PostgreSQL's full text search.
  * Fast (< 100 ms per request)
* Mileage search: Search the combination of line number and mileage.

## Delevopment goals

The code of this application should be easy to read and it should be fast. We avoid unnecessary overhead
and aim to make as much use as possible of indexes in the database.

## API

See the [OpenAPI specification](openapi.yaml).

## Setup

### Dependencies and Deployment

This API runs as a Python WSGI application. You need a WSGI server and a web server. For development
purposes, you can just run `python3 api.py serve`.

Dependencies:

* Python 3
* [Werkzeug](https://werkzeug.palletsprojects.com/)
* [Psycopg2](https://www.psycopg.org/docs/)

### Installation

Install the dependencies listed above:

```shell
apt install python3-werkzeug python3-psycopg2
```

If you want to deploy it on a server (not just run in development mode locally):

```shell
apt install apache2 libapache2-mod-wsgi-py3
```

Import OpenStreetMap data as described in the map style setup guide. You have to follow the following sections only:

* Dependencies (Kosmtik, Nik4 and PyYAML are not required)
* Database Setup
* Load OSM Data into the Database

Create database views:

```shell
sudo -u osmimport psql -d gis -f prepare_facilities.sql
sudo -u osmimport psql -d gis -f prepare_milestone.sql

Create a database user for the user running the API (either the user running Apache – often called www-data or httpd – or your user account in dev mode) and grant read permissions to this user:

```shell
createuser $USERNAME
sudo -u postgres psql -d gis -c "GRANT SELECT ON TABLES IN SCHEMA PUBLIC TO $USERNAME;"
```

### Database updates

If you apply OSM diff updates to the database, do not forget to run the `update_*.sql` scripts afterwards to refresh the materialized views:

```shell
sudo -u osmimport psql -d gis -f update_facilities.sql
sudo -u osmimport psql -d gis -f update_milestone.sql
```

## License

This project is licensed under the terms of GPLv2 or newer. You can find a copy of version 3 of the license in the [COPYING](COPYING) file.

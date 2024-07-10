**This is experimental code. It is not ready for production yet.**

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

### Facilities

URL: `/facility?<PARAMETERS>`

The facility endpoint returns detail of a facility (station, junction, yard, …) by its name, UIC reference or reference.

The request must contain exactly one of the following parameters because they are mutually exclusive:

* `q=<string>`: search term (will be looked up in all `name=*` tags, `railway:ref=*` and `uic_ref=*`).
* `name=<string>`: search term (name search only)
* `ref=<string>`: serach by official facility reference number/code only
* `uic_ref=<string>`: search by UIC reference number of a station (uses OSM tag `uic_ref=*`)

Optional parameter:

* `limit=<integer>`: maximum number of results, optional, defaults to 20, must not exceed 200

It takes the first keyword of (name,uicref,ref) and the optional the operator to search for the data.

The API returns JSON formatted data with following fields:

  * `latitude`: latitude
  * `longitude`: longitude
  * `osm_id`: OSM node ID
  * `rank`: an importance rank calculated by taking the public transport route relations into account using this station/halt
  * All OSM tags present on this object. The following tags are very often in use. See the OSM wiki and Taginfo for a more comprehensive list of possible tags.
    * `name`: name
    * `uic_name`: UIC station name
    * `railway:ref`: reference assigned by the operator of the infrastructure
    * `railway`: type of the facility following [Tagging rules](https://wiki.openstreetmap.org/wiki/OpenRailwayMap/Tagging#Operating_Sites)), e.g. `station`, `halt`, `junction`, `yard`.
    * `operator`: operator of the infrastructure

Example:

Request: `GET https://api.openrailwaymap.org/v2/facility?name=Karlsruhe&limit=1`

Response:

```json
[
  {
    "osm_id": 2574283615,
    "name": "Karlsruhe Hauptbahnhof",
    "railway": "station",
    "ref": null,
    "iata": "KJR",
    "uic_ref": "8000191",
    "website": "https://www.bahnhof.de/bahnhof-de/bahnhof/Karlsruhe-Hbf-1019530",
    "operator": "DB Station&Service AG",
    "wikidata": "Q688541",
    "iata:note": "AIRail Flughafen",
    "max_level": "1",
    "min_level": "-1",
    "platforms": "7",
    "ref:IFOPT": "de:08212:90",
    "wikipedia": "de:Karlsruhe Hauptbahnhof",
    "short_name": "Karlsruhe Hbf",
    "wheelchair": "yes",
    "railway:ref": "RK",
    "ref:station": "3107",
    "internet_access": "wlan",
    "public_transport": "station",
    "internet_access:fee": "no",
    "internet_access:ssid": "Telekom",
    "internet_access:operator": "Deutsche Telekom AG",
    "railway:station_category": "1",
    "internet_access:fee:description": "30min kostenlos",
    "latitude": 8.4020518,
    "longitude": 48.9936163996939,
    "rank": 176
  }
]
```

### Milestones

The milestone endpoint returns the position of milestones or other items such as signals or level crossings with a mapped position on a line.

The API will return the features within a maximum distance of 10 km (hardcoded). The presence of an `operator=*` tag on the tracks is honoured, it will be used to
distinguish reference numbers used by different infrastructure operators and/or in different countries.

Mileage is read from the OSM tags `railway:position=*` and `railway:position:exact=*` with precedence of the exact mileage. The tracks must be tagged with a reference number (OSM tag `ref=*`).

The tracks must not tagged with `service=*` (this condition does not apply to tracks with `usage=industrial/military/test`).

Negative mileage is supported but gaps in mileage or duplicated positions (if railway lines are reroute) are not supported. For example, you cannot query for `16.8+200` or things like that.

URL: `/milestone?<PARAMETERS>`

Mandatory parameters:

* `ref=<string>`: reference number of the railway route the mileage refers to (in this case, route meas lines as infrastructure, not the services using the tracks), mandatory
* `position=<float>`: position (can be negative), mandatory

Optional parameter:

* `limit=<integer>`: maximum number of results, optional, defaults to 2, must not exceed 200

The API returns JSON formatted data with following fields:

  * `osm_id`: OSM node ID
  * `latitude`: latitude
  * `longitude`: longitude
  * `position`: Mileage of the feature
  * `railway`: type of the facility following [Tagging rules](https://wiki.openstreetmap.org/wiki/OpenRailwayMap/Tagging#Operating_Sites)), e.g. `milestone`, `level_crossing`, `signal`.
  * `ref`: Reference number of the railway line the feature is located on.
  * `operator`: operator of the infrastructure

Example:

Request: `GET https://api.openrailwaymap.org/v2/milestone?ref=4201&position=18.4`

Response:

```json
[
  {
    "osm_id": 3479484133,
    "railway": "milestone",
    "position": 18.405,
    "latitude": 8.7064769,
    "longitude": 49.0315238996845,
    "ref": "4201",
    "operator": "Albtal-Verkehrs-Gesellschaft mbH"
  },
  {
    "osm_id": 3479484134,
    "railway": "milestone",
    "position": 18.2,
    "latitude": 8.7045853,
    "longitude": 49.0327703996842,
    "ref": "4201",
    "operator": "Albtal-Verkehrs-Gesellschaft mbH"
  }
]
```

### Network length

The previous (v1) version of the API provided a `/networklength` entpoint. It returned the length of the railway networks of the infrastructure operators.
Calls to the endpoint cause long database queries. The endpoint was not used in the frontend. Therefore, this endpoint is not available in version 2.

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

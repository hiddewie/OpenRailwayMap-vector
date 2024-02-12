# Setup

This guide mainly covers setup for development purposes. If you set up a tile server, follow the guides at [switch2osm.org](https://switch2osm.org) and adapt the style specific steps by those listed in the overview section of this guide.

## Building quickly

Building the Mapnik XML files does not require access to a PostgreSQL database with OSM data in it.
If you just want to generated the Mapnik XML files and have `carto` in your path, run the following
command (Python 3 and PyYAML are required as build dependencies in addition to Carto):

```sh
make
```

## Overview for Experienced Developers

If you are experienced with CartoCSS map styles and their setup, this section contains the important information for you.

This style requires a database imported with Osm2pgsql including slim tables in Web Mercator projection.

The database name is `gis` (Osm2pgsql default) but you can change this in header of the .mml files.

We use the same database layout as [OpenStreetMap Carto](https://github.com/gravitystorm/openstreetmap-carto) in order to allow rendering other common map styles from the same database. The Osm2pgsql style file and the Lua tag transforms file are included in the `setup/` subdirectory.

The ordering of stations for label rendering requires slim tables to access the membership of stop positions, platforms and stations in route relations. Unfortunately, the access to the members field of `planet_osm_rels` is not performant. Therefore, a [materialized view](https://www.postgresql.org/docs/current/rules-materializedviews.html) is created to cache the results of the computation.

Therefore, the following options are required for Osm2pgsql: `--slim --merc --style setup/openstreetmap-carto.style --tag-transform setup/openstreetmap-carto.lua --hstore`

After importing OSM data into the database, you have to create a couple of views, install some custom functions and compute the label ranking of stations. Please run the following SQL scripts in the following order:

```sh
psql -d gis -f sql/functions.sql
psql -d gis -f sql/osm_carto_views.sql
psql -d gis -f sql/get_station_importance.sql
```

If you update your data, you have to refresh the materialized view of the train stations and their importance using `psql -d gis -f sql/update_station_importance.sql`.


## Detailed Instructions for Development Setup

The detailed instructions cover the setup on Linux and might work on OS X. Windows is not supported because Mapnik dropped Windows support in 2018 due to a lack of sufficiently experienced volunteers.


### Dependencies

* PostgreSQL
* PostGIS
* Osm2pgsql
* optional: Osmium Tool
* Carto
* development only: Kosmtik or Nik4

Build dependencies required for using the Makefile:

* Python 3
* PyYAML

### Database Setup

Install PostgreSQL and PostGIS. Your distribution likely provides packages for PostgreSQL and PostGIS.

Debian-like systems: `sudo apt install postgresql postgis postgresql-client postgresql-10-postgis-2.4` (you might have to adapt the version numbers of PostgreSQL and PostGIS, there is no metapackage)

Create a database user. PostgreSQL provides a command line programme called *createuser* for that purpose. It has to be called using the permissions of the user running PostgreSQL – that's usually `postgres`.

Debian-like systems: `sudo -u postgres createuser --superuser $USER`

We granted superuser permissions to our user to avoid usage of sudo for further steps.

Now we can create an empty database:

```sh
createdb -E utf8 -O $USER gis
```

If PostgreSQL asks for a password or other authentication problems occur, you have to ensure that the `peer` authentication method is enabled. It allows you to log into the database as a user having the same username as your system account (i.e. if your are logged into Linux as franz, you will be able to log into PostgreSQL as franz as well). To enable the `peer` method, add the following line to `pg_hba.conf` (location on Debian systems: `/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf`). Replace `$USER` by your username. See chapter 20.3 and 20.9 of the [PostgreSQL documentation](https://www.postgresql.org/docs/current/client-authentication.html) for details about client authentication.

```
local all $USER  peer
```

After creating the database called `gis`, you have to enable two extensions:

```sh
psql -d gis -c "CREATE EXTENSION postgis;"
psql -d gis -c "CREATE EXTENSION hstore;"
```

PostgreSQL will return the string `CREATE EXTENSION` on success.

The PostGIS extension provides a geometry data type and spatial indexes, the Hstore extension provides a key value mapping type.



### Load OSM Data into the Database

We can now load OSM raw data into the database using Osm2pgsql. This guide will not explain the installation of Osm2pgsql. It is likely available from the package repositories of your Linux distribution or you compile it from source (see the [readme file of Osm2pgsql](https://github.com/OpenStreetMap/osm2pgsql) for details). We do not need a very recent version of Osm2pgsql, therefore installing Osm2pgsql from the package repositories should be fine.

Debian-like systems: `sudo apt install osm2pgsql`

You now have the choice between the following options (choose option 4 for development setups and option 1 or 2 for production):

* Import full planet dump in .osm.pbf format from [planet.openstreetmap.org](https://planet.openstreetmap.org). This will take at least half a day and require a few hundred GB SSD space. It is the easiest option if you want to update your database more often than every day. The database should be located on a SSD if you choose this option.
* Import a filtered planet dump containing railway features only. This still requires downloading the planet dump but you will extract only railway features using Osmium Tool but takes only about 1/20 of disk space and time.
* Import a regional extract from [download.geofabrik.de](https://download.geofabrik.de/) in .osm.pbf format. This is way faster depending on the size of the extract.
* Import a filtered regional extract by downloading a regional extract from [download.geofabrik.de](https://download.geofabrik.de/) in .osm.pbf format and filtering it with Osmium Tool before importing it with Osm2pgsql.

If you choose to filter a planet dump or regional extract, use Osmium Tool and call it as following. Please refer to the [Osmium documentation](https://osmcode.org/osmium-tool/) and its [readme file](https://github.com/osmcode/osmium-tool/blob/master/README.md) for installation and build instructions.

```sh
osmium tags-filter -o filtered.osm.pbf input.osm.pbf nwr/railway nwr/disused:railway nwr/abandoned:railway nwr/razed:railway nwr/construction:railway nwr/proposed:railway n/public_transport=stop_position nwr/public_transport=platform r/route=train r/route=tram r/route=light_rail r/route=subway
```

We are ready to call Osm2pgsql now.

```sh
osm2pgsql --create --database gis --hstore --slim --merc --style setup/openstreetmap-carto.style --tag-transform setup/openstreetmap-carto.lua --multi-geometry --cache $CACHE_SIZE filtered.osm.pbf
```

`$CACHE_SIZE` should be sufficiently large. See the [recommendations of the Osm2pgsql developers](https://github.com/OpenStreetMap/osm2pgsql#usage). If you import a full planet dump, you should also add the option `--flat-nodes $PATH_TO_FLAT_NODES_FILE` pointing to a location in your file system on a SSD where a more than 40 GB (to be precise: `8 * max_osm_node_id` Byte) large file to store the locations of all OSM nodes can be placed. For full planet imports and imports of at least half the size of the planet, a flat nodes file is recommended. Otherwise, Osm2pgsql will store node locations in the database which requires more SSD space.


### Create Database Views and Pre-calculate Station Label Ranking

The map style accesses the database through a couple of views. In addition, it requires a few custom functions and a precomputed station label ranking. Please run the following SQL scripts in the described order:

```sh
psql -d gis -f sql/functions.sql
psql -d gis -f sql/osm_carto_views.sql
psql -d gis -f sql/get_station_importance.sql
```

If you update your database, you have to refresh the materialized view of the train stations periodically. Call `psql -d gis -f sql/update_station_importance.sql` to refresh it.


### Install Carto

This step is required for

* production setups
* development setups using Nik4

The map style is written in CartoCSS which will be transpiled to Mapnik XML using the [Carto](https://github.com/mapbox/carto) tool. You can either install it from the package repositories of your distribution (called `nodejs-carto` or `node-carto`) or – without root permissions – using `npm install carto` in a directory of your choice.

You can now transpile the CartoCSS styles into Mapnik XML using:

```sh
carto project.mml > standard.xml
carto maxspeed.mml > maxspeed.xml
carto signals.mml > signals.xml
```

The resulting XML files are read by the Mapnik library – either using tools such as Nik4 or tile server software such as Rendered or Tirex.

If you use Kosmtik for development, you will not have to call Carto yourself, Kosmtik does this for you, it requires Carto as dependency.


### Development Setup only: Install Kosmtik

Kosmtik is a simple map viewer running locally and rendering tiles live on demand. It comes with a simple web map viewer. You can install it using `npm install kosmtik` in a directory of your choice.

To start Kosmtik call

```sh
node_modules/kosmtik/index.js serve path_to_openrailwymap_styles/project.mml
```

Change the name of the .mml file if you want to work on a style other than the infrastructure style.

You can now view the map in your browser at [http://127.0.0.1:6789/](http://127.0.0.1:6789/). If you save changes to the .mml or .mss files, Kosmtik will rebuild the Mapnik XML style and re-render the map tiles.


### Makefile setup

If you want to use the Makefile to build the Mapnik XML style files, additional build dependencies (see above) are required.

Debian-like systems: `apt install python3 python3-yaml`


### Development Setup only: Install Nik4

If you get strange exceptions thrown during installing Kosmtik, using Nik4 to render map images on demand is an alternative. Nik4 is a Python programme making use of the Mapnik's Python bindings. You can install Nik4 either from the package repository of your distribution (often called `nik4` or `python-nik4`) or using `pip install nik4`.

If you choose this path, you have to install Carto as well (see above).

Your development work flow would be the following:

* edit the .mml or .mss files
* call `carto $STYLE.mml > $STYLE.xml`
* render map images of the location and zoom you would like to see: `nik4 -c $CENTER_LONGITUDE $CENTER_LATITUDE -z $ZOOM_LEVEL -x 2048 2048 $STYLE.xml output.png`

## Docker

Use the Docker setup to get a development environment up and running quickly.

This setup only requires Docker and Docker Compose to be installed, but and requires no other dependencies. This setup should also work on Windows systems (the containers will run in a virtual machine).

- Run `docker compose up db` to start the Postgres database.
- Download a file with the OSM data, and name it `data.osm.pbf`. Run `docker compose up import` which will import the data, run the post-import database setup. This step also creates a file `.env` with environment variables that you can use to tune the import.
- Run `docker compose up kosmtik` to start Kosmtik and view the map style. Edit the `command` argument in `docker-compose.yml` in order to render a different style (default `standard.mml`).

Go to http://127.0.0.1:6789 to view the OpenRailwayMap. Make changes to the OpenRailwayMap style or assets, and Kosmtik will auto-reload the changes.

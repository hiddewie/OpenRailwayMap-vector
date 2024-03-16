# OpenRailwayMap Vector Map Styles

This repository contains the visualization of railway infrastructure, speed limits, train protection, electrification and railway gauges using vector-based tiles and a web-based user interface. 

Documentation can be found on the [OpenStreetMap Wiki](https://wiki.openstreetmap.org/wiki/OpenRailwayMap).

## Architecture

This repository aims to contain all code, configuration and tooling for the OpenRailwayMap.

- Data is provided by [OpenStreetMap](https://www.openstreetmap.org/about).
- Data is stored in a [PostgreSQL](https://www.postgresql.org/) database, augmented by [PostGIS](https://postgis.net/) for spatial features.
- Data is imported from the OpenStreetMap data files to PostgreSQL using [Osm2pgsql](https://osm2pgsql.org/).
- Vector tiles are rendered from the database with [Martin](https://martin.maplibre.org/) (part of the [MapLibre initiative](https://maplibre.org/)) in the MBtiles format.
- The user interface uses [MapLibre GL JS](https://maplibre.org/maplibre-gl-js/docs/) to visualize the map content.
- The style is specified using the [MapLibre Style Specification](https://maplibre.org/maplibre-style-spec/).
- [Docker](https://www.docker.com/) is used to package the software and data for local development and deployment.
- Deployment is done using [`fly.io`](https://fly.io/).

## Changes from the CartoCSS style

A number of changes have been made from the [upstream `OpenRailwayMap-CartoCSS` project](https://github.com/OpenRailwayMap/OpenRailwayMap-CartoCSS):
- The raster tiles have been replaced with vector tiles.
- MapCSS and Mapnik have been replaced with the MapLibre Style Specification and Martin.
- Database views have been collapsed into single views to minimize data transfer.
- Lua code is used to minimize imported data, while retaining the ability to change the database views for adding new features. 
- Visualization of additional signalling has been added.
- Direction of railway signals has been added.
- Fixes have been made for non-functional visualization rules.

Upstream changes will be merged into this project.

## Contributing

Contributions are welcome!

There are multiple ways to contribute to this project:
- Improving the code and/or tooling.
- Providing more details for visualization on the map, for the infrastructure, speed limit, train protection, electrification or gauge layer.
- Providing icons for visualizing features on the map.
- Providing translations for currently supported or new languages.
- Providing user interface improvements.
- Providing technical or user documentation.

View the [contribution documentation](CONTRIBUTING.md) for details.

## Local development and deployment

To run the OpenRailwayMap locally, you can import OpenStreetMap data and run the tile and web server locally.

View the [setup documentation](SETUP.md) for details.

## License

Copyright © 2024 Hidde Wieringa

The [original map style (CartoCSS)](https://github.com/OpenRailwayMap/OpenRailwayMap-CartoCSS/)
is copyright © 2017–2019 Michael Reichert

The [original map style (MapCSS)](https://github.com/OpenRailwayMap/OpenRailwayMap/tree/master/styles)
is Copyright © 2012 Alexander Matheisen

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/.

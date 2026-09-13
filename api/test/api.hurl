# Status
GET {{base_url}}/status
HTTP 200

# Replication timestamp
GET {{base_url}}/replication_timestamp
HTTP 200
[Asserts]
jsonpath "$.replication_timestamp" != null
jsonpath "$.import_timestamp" != null

# Facility request
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$" count == 20
jsonpath "$[0].name" == "Berlin Hauptbahnhof (tief)"
jsonpath "$[1].name" == "S+U Hauptbahnhof"
jsonpath "$[2].name" == "Berlin Hauptbahnhof"
jsonpath "$[3].name" == "Hauptbahnhof"
jsonpath "$[4].name" == "Hauptbahnhof"
jsonpath "$[5].name" == "Berlin Hauptbahnhof Tunnel (S-Bahn)"
jsonpath "$[6].name" == "Berlin Südkreuz"
jsonpath "$[7].name" == "Südkreuz (Ringbahn)"
jsonpath "$[8].name" == "Südkreuz (Nord-Süd)"
jsonpath "$[9].name" == "Berlin-Spandau"
jsonpath "$[10].name" == "Spandau"
jsonpath "$[11].name" == "Ostbahnhof"
jsonpath "$[12].name" == "Berlin Ostbahnhof"
jsonpath "$[13].name" == "Berlin Gesundbrunnen"
jsonpath "$[14].name" == "Gesundbrunnen"
jsonpath "$[15].name" == "Berlin Alexanderplatz"
jsonpath "$[16].name" == "Alexanderplatz"
jsonpath "$[17].name" == "Berlin Friedrichstraße"
jsonpath "$[18].name" == "Ostkreuz"
jsonpath "$[19].name" == "S Friedrichstraße"

# Facility request with language
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin Ostbahnhof
lang: en
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].name" == "Ostbahnhof"
jsonpath "$[0].localized_name" == "Ostbahnhof"
jsonpath "$[1].name" == "Berlin Ostbahnhof"
jsonpath "$[1].localized_name" == "Berlin Eastern Station"

# Facility request with limit
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
limit: 5
HTTP 200
[Asserts]
jsonpath "$" count == 5

# Facility request with larger limit
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
limit: 25
HTTP 200
[Asserts]
jsonpath "$" count == 25

# Facility request too large limit
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
limit: 201
HTTP 422
[Asserts]
jsonpath "$.detail[0].msg" == "Input should be less than or equal to 200"

# Facility request too small limit
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
limit: 0
HTTP 422
[Asserts]
jsonpath "$.detail[0].msg" == "Input should be greater than or equal to 1"

# Facility request with hyphen
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin-Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 7
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Berlin-Spandau Johannesstift"
jsonpath "$[3].name" == "Berlin-Spandau Gbf"
jsonpath "$[4].name" == "Berlin-Spandau West"
jsonpath "$[5].name" == "Berlin-Spandau Mitte"
jsonpath "$[6].name" == "Berlin-Spandau Ost"

# Facility request with space
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 7
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Berlin-Spandau Johannesstift"
jsonpath "$[3].name" == "Berlin-Spandau Gbf"
jsonpath "$[4].name" == "Berlin-Spandau West"
jsonpath "$[5].name" == "Berlin-Spandau Mitte"
jsonpath "$[6].name" == "Berlin-Spandau Ost"

# Facility request for Spandau
GET {{base_url}}/facility
[QueryStringParams]
name: Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 9
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Berlin-Spandau Johannesstift"
jsonpath "$[3].name" == "Berlin-Spandau Gbf"
jsonpath "$[4].name" == "Rathaus Spandau"
jsonpath "$[5].name" == "Altstadt Spandau"
jsonpath "$[6].name" == "Berlin-Spandau West"
jsonpath "$[7].name" == "Berlin-Spandau Mitte"
jsonpath "$[8].name" == "Berlin-Spandau Ost"

# Facility request with diacritics
GET {{base_url}}/facility
[QueryStringParams]
name: Karl-Marx-Straße
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Karl-Marx-Straße"

# Facility request with name containing /
GET {{base_url}}/facility
[QueryStringParams]
name: Königsheideweg
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Sterndamm/Königsheideweg"

# Facility search for reference
GET {{base_url}}/facility
[QueryStringParams]
ref: BOKN
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Berlin Ostkreuz (Ringbahn-F)"
jsonpath "$[0].osm_ids" count == 1
jsonpath "$[0].osm_types" count == 1
jsonpath "$[0].osm_ids[0]" == 4746086763
jsonpath "$[0].osm_types[0]" == "N"

# Facility search for reference
GET {{base_url}}/facility
[QueryStringParams]
ref: BOKN
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Berlin Ostkreuz (Ringbahn-F)"

# Facility search by reference for yard (area)
GET {{base_url}}/facility
[QueryStringParams]
ref: BNO
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Berlin Nordost"

# Facility search for UIC reference
GET {{base_url}}/facility
[QueryStringParams]
ref: 8089028
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].name" == "Ostkreuz"
jsonpath "$[1].name" == "Ostkreuz (Ringbahn)"

# Facility search for BVG reference
GET {{base_url}}/facility
[QueryStringParams]
ref: 309771
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Virchowstraße"
jsonpath "$[0].references.de-bvg" == "309770"

# Facility search for name or reference
GET {{base_url}}/facility
[QueryStringParams]
q: BOK
HTTP 200
[Asserts]
jsonpath "$" count == 4
jsonpath "$[0].name" == "Ostkreuz (Ringbahn)"
jsonpath "$[1].name" == "Rummelsburg"
jsonpath "$[2].name" == "S Frankfurter Allee"
jsonpath "$[3].name" == "Treptower Park"

# Facility search for name or reference
GET {{base_url}}/facility
[QueryStringParams]
q: Berlin Ostkreuz
HTTP 200
[Asserts]
jsonpath "$" count == 5
jsonpath "$[0].name" == "Ostkreuz"
jsonpath "$[1].name" == "Berlin Ostkreuz (Stadtbahn-F)"
jsonpath "$[2].name" == "Berlin Ostkreuz (Ringbahn-F)"
jsonpath "$[3].name" == "Berlin Ostkreuz (Ostbahn)"
jsonpath "$[4].name" == "Ostkreuz (Ringbahn)"

# Facility search for name or reference
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].name" == "Ostkreuz"
jsonpath "$[1].name" == "Ostkreuz (Ringbahn)"

# Facility search for name or reference for grouped station
GET {{base_url}}/facility
[QueryStringParams]
q: Landsberger Allee
HTTP 200
[Asserts]
jsonpath "$" count == 6
jsonpath "$[0].name" == "Landsberger Allee/Petersburger Straße"
jsonpath "$[0].feature" == "tram_stop"
jsonpath "$[0].state" == "present"
jsonpath "$[0].rank" == 34
jsonpath "$[0].osm_ids" count == 4
jsonpath "$[0].osm_ids[0]" == 244129991
jsonpath "$[0].osm_ids[1]" == 271777826
jsonpath "$[0].osm_ids[2]" == 1679221136
jsonpath "$[0].osm_ids[3]" == 1787945074
jsonpath "$[0].osm_types" count == 4
jsonpath "$[3].railway_ref" == "BLST"
jsonpath "$[3].station" == "light_rail"
jsonpath "$[3].uic_ref" == "8089020"
jsonpath "$[3].operator[0]" == "DB InfraGO AG"
jsonpath "$[3].network[0]" == "Verkehrsverbund Berlin-Brandenburg"
jsonpath "$[3].wikidata[0]" == "Q800507"
jsonpath "$[3].wikipedia[0]" == "de:Bahnhof Berlin Landsberger Allee"

# Facility request missing required parameter
GET {{base_url}}/facility
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "No argument with a search term provided."
jsonpath "$.detail.detail" == "Provide one of the following query parameters: q, name, ref"

# Facility request duplicated search parameters (1)
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref"

# Facility request duplicated search parameters (2)
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref"

# Facility request duplicated search parameters (3)
GET {{base_url}}/facility
[QueryStringParams]
q: test
name: test
ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref"

# Facility request limit is not numeric
GET {{base_url}}/facility
[QueryStringParams]
limit: blabla
HTTP 422
[Asserts]
jsonpath "$.detail" count == 1
jsonpath "$.detail[0].msg" == "Input should be a valid integer, unable to parse string as an integer"

# Milestone request for line 6020 milestone 22.7
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: 22.7
limit: 1
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].line_ref" == "6020"
jsonpath "$[0].position" == "22.7"

# Milestone request too small limit
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: 22.7
limit: 0
HTTP 422
[Asserts]
jsonpath "$.detail" count == 1
jsonpath "$.detail[0].msg" == "Input should be greater than or equal to 1"

# Milestone request too large limit
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: 22.7
limit: 201
HTTP 422
[Asserts]
jsonpath "$.detail" count == 1
jsonpath "$.detail[0].msg" == "Input should be less than or equal to 200"

# Milestone request missing required ref and position parameters
GET {{base_url}}/milestone
HTTP 422
[Asserts]
jsonpath "$.detail" count == 2
jsonpath "$.detail[0].msg" == "Field required"
jsonpath "$.detail[1].msg" == "Field required"

# Milestone request with non-numeric arguments
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: blabla
HTTP 422
[Asserts]
jsonpath "$.detail" count == 1
jsonpath "$.detail[0].msg" == "Input should be a valid number, unable to parse string as a number"

# Milestone request with non-numeric arguments
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: 22.7
limit: blabla
HTTP 422
[Asserts]
jsonpath "$.detail" count == 1
jsonpath "$.detail[0].msg" == "Input should be a valid integer, unable to parse string as an integer"

# Route
GET {{base_url}}/route/64050
HTTP 200
Content-Type: application/geo+json
[Asserts]
jsonpath "$.id" == 64050
jsonpath "$.type" == "Feature"
jsonpath "$.properties.to" == "S Spindlersfeld"
jsonpath "$.properties.ref" == "S47"
jsonpath "$.properties.from" == "S Südkreuz"
jsonpath "$.properties.name" == "S47: S Südkreuz => S Spindlersfeld"
jsonpath "$.properties.type" == "light_rail"
jsonpath "$.properties.color" == "#BA8A4D"
jsonpath "$.properties.osm_id" == 64050
jsonpath "$.properties.operator" == "S-Bahn Berlin GmbH"
jsonpath "$.geometry.type" == "LineString"
jsonpath "$.geometry.coordinates" count > 0

# Non existing route
GET {{base_url}}/route/404
HTTP 404

# Route stops
GET {{base_url}}/route/stops/64050
HTTP 200
Content-Type: application/geo+json
[Asserts]
jsonpath "$.type" == "FeatureCollection"
jsonpath "$.features" count == 9
jsonpath "$.features[0].id" == 4946539230
jsonpath "$.features[0].type" == "Feature"
jsonpath "$.features[0].geometry.type" == "Point"
jsonpath "$.features[0].geometry.coordinates[0]" == 13.3654535
jsonpath "$.features[0].geometry.coordinates[1]" == 52.475174499
jsonpath "$.features[0].properties.name" == "Südkreuz"
jsonpath "$.features[0].properties.type" == "train"
jsonpath "$.features[0].properties.osm_id" == 4946539230

# Non existing route
GET {{base_url}}/route/stops/404
HTTP 200
Content-Type: application/geo+json
[Asserts]
jsonpath "$.type" == "FeatureCollection"
jsonpath "$.features" count == 0

# Non existing WikiData image
GET {{base_url}}/wikidata/Q0
HTTP 404
Content-Type: text/plain; charset=utf-8
[Asserts]
body == "Response from Wikidata API had status 400"

# WikiData image with metadata
GET {{base_url}}/wikidata/Q660045
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.file_name" == "2012-03-06_Berlin_Ostkreuz_vom_Treptower.jpg"
jsonpath "$.description" == "Image 2012-03-06 Berlin Ostkreuz vom Treptower.jpg from Wikidata Q660045: Berlin, <a href=\"https://en.wikipedia.org/wiki/Ostkreuz\" class=\"extiw\" title=\"en:Ostkreuz\">Ostkreuz</a>"
jsonpath "$.view_url" == "https://www.wikidata.org/wiki/Q660045#/media/File:2012-03-06_Berlin_Ostkreuz_vom_Treptower.jpg"
jsonpath "$.thumbnail_url" == "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/2012-03-06_Berlin_Ostkreuz_vom_Treptower.jpg/330px-2012-03-06_Berlin_Ostkreuz_vom_Treptower.jpg"
jsonpath "$.attribution" == "Wo st 01 / Wikimedia Commons"
jsonpath "$.license" == "CC BY-SA 3.0 de"
jsonpath "$.license_url" == "https://creativecommons.org/licenses/by-sa/3.0/de/deed.en"

# WikiMedia image with metadata
GET {{base_url}}/wikimedia/U-Bahnhof%20Wuhletal.jpg
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.file_name" == "U-Bahnhof_Wuhletal.jpg"
jsonpath "$.description" == "Image U-Bahnhof Wuhletal.jpg from Wikimedia Commons: U-Bahnhof Wuhletal (station du métro de Berlin, Allemagne)"
jsonpath "$.view_url" == "https://commons.wikimedia.org/wiki/File:U-Bahnhof%20Wuhletal.jpg#/media/File:U-Bahnhof_Wuhletal.jpg"
jsonpath "$.thumbnail_url" == "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/U-Bahnhof_Wuhletal.jpg/330px-U-Bahnhof_Wuhletal.jpg"
jsonpath "$.attribution" == "Molgreen, Own work"
jsonpath "$.license" == "CC BY-SA 4.0"
jsonpath "$.license_url" == "https://creativecommons.org/licenses/by-sa/4.0"

# Features
GET {{base_url}}/features/features.json
HTTP 200
Content-Type: application/json

# Feature does not exist
GET {{base_url}}/feature/layer-does-not-exist/source-does-not-exist/404
HTTP 404

# Signal box
GET {{base_url}}/feature/openrailwaymap_signals/signals_signal_boxes/way-485364317
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.osm_id" == 485364317
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.feature" == "signal_box"
jsonpath "$.properties.name" == "Biesdorfer Kreuz ESTW-A"
jsonpath "$.properties.operator" == "DB InfraGO"
jsonpath "$.properties.ref" == "BBIK"

# Catenary mast
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_catenary/12329861010-mast
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 12329861010
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.feature" == "mast"
jsonpath "$.properties.supporting" == "cantilever"
jsonpath "$.properties.position" count == 1
jsonpath "$.properties.position[0]" == "11.6 (km)"
jsonpath "$.properties.structure" == "lattice"

# Substation
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_substation/62032242
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 62032242
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.voltage" count == 2
jsonpath "$.properties.voltage[0]" == 30000
jsonpath "$.properties.voltage[1]" == 750

# Substation
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_substation/320522867
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 320522867
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.conversion" == "30 kV 50.00 Hz ⇒ 750 V ="

# Railway crossing
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_switch_ref/2101295628
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 2101295628
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.railway" == "railway_crossing"

# Switch
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_switch_ref/2614563600
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 2614563600
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.railway" == "switch"
jsonpath "$.properties.ref" == "W3"
jsonpath "$.properties.resetting" == true
jsonpath "$.properties.local_operated" == true
jsonpath "$.properties.type" == "default"

# Railway position
GET {{base_url}}/feature/high/railway_text_km/260827078-1
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == "Bei den DB-Open-Data nicht genau erkennbar welcher von beiden der 3.255 und welcher der 3.256 ist, daher beide 3.256"
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 260827078
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.pos" == "3.2"
jsonpath "$.properties.pos_exact" == "3.256"
jsonpath "$.properties.railway" == "crossing"

# Stop position
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_stop_positions/1615531689
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.osm_id" == 1615531689
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.type" == "tram"
jsonpath "$.properties.local_ref" == "14"
jsonpath "$.properties.ref" == null
jsonpath "$.properties.name" == "S+U Alexanderplatz/Dircksenstraße"
jsonpath "$.properties.stop_position_routes" count == 4
jsonpath "$.properties.stop_position_routes[0].label" == "Tram M2: S+U Alexanderplatz => Heinersdorf"
jsonpath "$.properties.stop_position_routes[0].color" == "#33FF33"
jsonpath "$.properties.stop_position_routes[0].route_id" == "28270"

# Station
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_text_stations/node-30217208-train-train-halt
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" count == 1
jsonpath "$.properties.note[0]" == "Berlin Alexanderplatz (Fernbahngleise) ist von der S-Bahn-Station unabhängig und nur ein Haltepunkt, da es keine einzige Weiche gibt."
jsonpath "$.properties.description" == null
jsonpath "$.properties.station" == "train"
jsonpath "$.properties.name" == "Berlin Alexanderplatz"
jsonpath "$.properties.localized_name" == "Berlin Alexanderplatz"
jsonpath "$.properties.yard_hump" == null
jsonpath "$.properties.wikidata" count == 1
jsonpath "$.properties.wikidata[0]" == "Q698497"
jsonpath "$.properties.network" count == 1
jsonpath "$.properties.network[0]" == "Verkehrsverbund Berlin-Brandenburg"
jsonpath "$.properties.osm_id" count == 1
jsonpath "$.properties.osm_id[0]" == 30217208
jsonpath "$.properties.osm_type" count == 1
jsonpath "$.properties.osm_type[0]" == "N"
jsonpath "$.properties.references.uic" == "8089001"
jsonpath "$.properties.references.station" == "53"
jsonpath "$.properties.references.railway-ref" == "BALE"
jsonpath "$.properties.wikipedia" count == 1
jsonpath "$.properties.wikipedia[0]" == "de:Bahnhof Berlin Alexanderplatz"
jsonpath "$.properties.state" == "present"
jsonpath "$.properties.feature" == "halt"
jsonpath "$.properties.station_routes" count == 38
jsonpath "$.properties.station_routes[0].label" == "Tram M2: S+U Alexanderplatz => Heinersdorf"
jsonpath "$.properties.station_routes[0].color" == "#33FF33"
jsonpath "$.properties.station_routes[0].route_id" == "28270"
jsonpath "$.properties.position" == null
jsonpath "$.properties.operator" count == 1
jsonpath "$.properties.operator[0]" == "DB InfraGO AG"

# Station with localized name
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_text_stations/node-30217208-train-train-halt
[QueryStringParams]
lang: ja
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.name" == "Berlin Alexanderplatz"
jsonpath "$.properties.localized_name" == "ベルリン・アレクサンダー広場"

# Station with not defined localization
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_text_stations/node-30217208-train-train-halt
[QueryStringParams]
lang: nf
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.name" == "Berlin Alexanderplatz"
jsonpath "$.properties.localized_name" == "Berlin Alexanderplatz"

# Stop area group
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_grouped_station_areas/7721002
[QueryStringParams]
lang: nf
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.osm_id" == 7721002
jsonpath "$.properties.osm_type" == "R"
jsonpath "$.properties.feature" == "station_area_group"

# Platform
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_platforms/relation-3637413
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.ref" count == 2
jsonpath "$.properties.ref[0]" == "1"
jsonpath "$.properties.ref[1]" == "2"
jsonpath "$.properties.surface" == "paving_stones"
jsonpath "$.properties.wheelchair" == true
jsonpath "$.properties.lit" == true
jsonpath "$.properties.shelter" == null
jsonpath "$.properties.bin" == true
jsonpath "$.properties.bench" == true
jsonpath "$.properties.departures_board" == null
jsonpath "$.properties.name" == "Berlin Alexanderplatz"
jsonpath "$.properties.platform_routes" count == 10
jsonpath "$.properties.platform_routes[0].label" == "RE2: Cottbus => Nauen"
jsonpath "$.properties.platform_routes[0].color" == "#FFE600"
jsonpath "$.properties.platform_routes[0].route_id" == "156479"
jsonpath "$.properties.feature" == "platform"
jsonpath "$.properties.height" == null
jsonpath "$.properties.tactile_paving" == true
jsonpath "$.properties.osm_id" == 3637413
jsonpath "$.properties.osm_type" == "R"

# Platform edge
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_platform_edges/859918234
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.ref" == "2"
jsonpath "$.properties.feature" == "platform_edge"
jsonpath "$.properties.tactile_paving" == null
jsonpath "$.properties.height" == null
jsonpath "$.properties.length" > 152.2
jsonpath "$.properties.length" < 152.3
jsonpath "$.properties.osm_id" == 859918234
jsonpath "$.properties.osm_type" == "W"

# POI (operator)
GET {{base_url}}/feature/openrailwaymap_operator/operator_railway_symbols/node-560099842
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.osm_id" == 560099842
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.feature" == "general/owner-change"

# POI (infrastructure)
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_symbols/way-140374295
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == "Container Terminal BeHaLa / City-GVZ Berlin"
jsonpath "$.properties.description" == null
jsonpath "$.properties.osm_id" == 140374295
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.feature" == "general/container-terminal"
jsonpath "$.properties.name" == "Container Terminal BeHaLa / City-GVZ Berlin"
jsonpath "$.properties.ref" == null

# Speed signal
GET {{base_url}}/feature/openrailwaymap_speed/speed_railway_signals/10719824502
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.osm_id" == 10719824502
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.ref" == "08ZV819"
jsonpath "$.properties.direction_both" == false
jsonpath "$.properties.railway" == "signal"
jsonpath "$.properties.feature0" == "de/zs3-sign-up-{40}"
jsonpath "$.properties['railway:signal:position']" == "right"
jsonpath "$.properties['railway:signal:speed_limit']" == "DE-ESO:zs3"
jsonpath "$.properties['railway:signal:speed_limit:form']" == "sign"
jsonpath "$.properties['railway:signal:speed_limit:speed']" count == 1
jsonpath "$.properties['railway:signal:speed_limit:speed'][0]" == "40"
jsonpath "$.properties['railway:signal:combined']" == "DE-ESO:ks"
jsonpath "$.properties['railway:signal:combined:form']" == "light"
jsonpath "$.properties['railway:signal:combined:height']" == "normal"
jsonpath "$.properties['railway:signal:combined:function']" == "intermediate"
jsonpath "$.properties['railway:signal:minor']" == "DE-ESO:sh1"
jsonpath "$.properties['railway:signal:minor:form']" == "light"
jsonpath "$.properties['railway:signal:traversable']" == "DE-ESO:mastschild_rot-weiss"
jsonpath "$.properties['railway:signal:traversable:type']" == "written_default_speed;dictated_default_speed"

# Electrification signal
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_signals/10720881143
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.osm_id" == 10720881143
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.ref" == null
jsonpath "$.properties.direction_both" == false
jsonpath "$.properties.railway" == "signal"
jsonpath "$.properties.feature0" == "de/el6-left"
jsonpath "$.properties['railway:signal:position']" == "right"
jsonpath "$.properties['railway:signal:electricity']" == "DE-ESO:el6"
jsonpath "$.properties['railway:signal:electricity:type']" == "end_of_catenary"
jsonpath "$.properties['railway:signal:electricity:form']" == "sign"
jsonpath "$.properties['railway:signal:electricity:turn_direction']" == "left"

# Distant signal
GET {{base_url}}/feature/openrailwaymap_signals/signals_railway_signals/9351388537
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.note" == null
jsonpath "$.properties.osm_id" == 9351388537
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.ref" == null
jsonpath "$.properties.direction_both" == false
jsonpath "$.properties.railway" == "signal"
jsonpath "$.properties.feature0" == "de/zs2v-{T}"
jsonpath "$.properties['railway:signal:distant']" == "DE-ESO:ks"
jsonpath "$.properties['railway:signal:distant:form']" == "light"
jsonpath "$.properties['railway:signal:distant:height']" == "normal"
jsonpath "$.properties['railway:signal:distant:repeated']" == true
jsonpath "$.properties['railway:signal:distant:states']" count == 2
jsonpath "$.properties['railway:signal:distant:states'][0]" == "DE-ESO:ks1"
jsonpath "$.properties['railway:signal:distant:states'][1]" == "DE-ESO:ks2"
jsonpath "$.properties['railway:signal:position']" == "right"
jsonpath "$.properties['railway:signal:route_distant']" == "DE-ESO:zs2v"
jsonpath "$.properties['railway:signal:route_distant:form']" == "light"
jsonpath "$.properties['railway:signal:route_distant:states']" count == 4
jsonpath "$.properties['railway:signal:route_distant:states'][0]" == "R"
jsonpath "$.properties['railway:signal:route_distant:states'][1]" == "S"
jsonpath "$.properties['railway:signal:route_distant:states'][2]" == "T"
jsonpath "$.properties['railway:signal:route_distant:states'][3]" == "off"
jsonpath "$.properties['railway:signal:speed_limit_distant']" == "DE-ESO:zs3v"
jsonpath "$.properties['railway:signal:speed_limit_distant:form']" == "light"
jsonpath "$.properties['railway:signal:speed_limit_distant:speed']" count == 2
jsonpath "$.properties['railway:signal:speed_limit_distant:speed'][0]" == "?"
jsonpath "$.properties['railway:signal:speed_limit_distant:speed'][1]" == "off"

# Turntable
GET {{base_url}}/feature/openrailwaymap_standard/standard_railway_turntables/16109013
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.osm_id" == 16109013
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.feature" == "turntable"
jsonpath "$.properties.diameter" == "23m"

# Entrance
GET {{base_url}}/feature/openrailwaymap_standard/standard_station_entrances/623932074
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.osm_id" == 623932074
jsonpath "$.properties.osm_type" == "N"
jsonpath "$.properties.type" == "subway"
jsonpath "$.properties.name" == "Yorckstraße"
jsonpath "$.properties.ref" == "E"

# Railway line
GET {{base_url}}/feature/high/railway_line_high/9933821-0
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.properties.electrification_state" == "present"
jsonpath "$.properties.feature" == "rail"
jsonpath "$.properties.frequency" == 16.700000762939453
jsonpath "$.properties.gauges" count == 1
jsonpath "$.properties.gauges[0]" == "1435"
jsonpath "$.properties.highspeed" == true
jsonpath "$.properties.line_routes" count == 14
jsonpath "$.properties.line_routes[0].color" == "#80004D"
jsonpath "$.properties.line_routes[0].label" == "RE4: Falkenberg (Elster) => Stendal Hauptbahnhof"
jsonpath "$.properties.line_routes[0].route_id" == "373229"
jsonpath "$.properties.operator" count == 1
jsonpath "$.properties.operator[0]" == "DB InfraGO AG"
jsonpath "$.properties.osm_id" == 9933821
jsonpath "$.properties.osm_type" == "W"
jsonpath "$.properties.ref" == "6185"
jsonpath "$.properties.name" == "Schnellfahrstrecke Oebisfelde–Spandau"
jsonpath "$.properties.speed_label" == "140"
jsonpath "$.properties.state" == "present"
jsonpath "$.properties.train_protection" count == 2
jsonpath "$.properties.train_protection[0]" == "lzb"
jsonpath "$.properties.train_protection[1]" == "pzb"
jsonpath "$.properties.usage" == "main"
jsonpath "$.properties.voltage" == 15000
jsonpath "$.properties.note" == null
jsonpath "$.properties.description" == null

# No test for interlocking because no such features exist in the test data

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
jsonpath "$[4].name" == "Berlin-Moabit"
jsonpath "$[5].name" == "Berlin Hamburger und Lehrter Bahnhof"
jsonpath "$[6].name" == "Berlin Südkreuz"
jsonpath "$[7].name" == "Südkreuz (Ringbahn)"
jsonpath "$[8].name" == "Südkreuz (Nord-Süd)"
jsonpath "$[9].name" == "Berlin Nordost"
jsonpath "$[10].name" == "Berlin-Ruhleben"
jsonpath "$[11].name" == "Berlin Greifswalder Straße"
jsonpath "$[12].name" == "Berlin-Grünau"
jsonpath "$[13].name" == "Berlin-Marienfelde Gbf"
jsonpath "$[14].name" == "Berlin-Spandau"
jsonpath "$[15].name" == "Spandau"
jsonpath "$[16].name" == "Berlin-Tempelhof"
jsonpath "$[17].name" == "Berlin-Schönholz"
jsonpath "$[18].name" == "Ostbahnhof"
jsonpath "$[19].name" == "Berlin Ostbahnhof"

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
jsonpath "$[1].localized_name" == "Berlin Ostbahnhof railway station"

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
jsonpath "$[2].name" == "Frankfurter Allee"
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
jsonpath "$.description" == "Berlin, <a href=\"https://en.wikipedia.org/wiki/Ostkreuz\" class=\"extiw\" title=\"en:Ostkreuz\">Ostkreuz</a>"
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
jsonpath "$.description" == "U-Bahnhof Wuhletal (station du métro de Berlin, Allemagne)"
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
jsonpath "$.note" == null
jsonpath "$.osm_id" == 485364317
jsonpath "$.osm_type" == "W"
jsonpath "$.feature" == "signal_box"
jsonpath "$.name" == "Biesdorfer Kreuz ESTW-A"
jsonpath "$.operator" == "DB InfraGO"
jsonpath "$.ref" == "BBIK"

# Catenary mast
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_catenary/12329861010-mast
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.note" == null
jsonpath "$.description" == null
jsonpath "$.osm_id" == 12329861010
jsonpath "$.osm_type" == "N"
jsonpath "$.feature" == "mast"
jsonpath "$.supporting" == "cantilever"
jsonpath "$.position" count == 1
jsonpath "$.position[0]" == "11.6 (km)"
jsonpath "$.structure" == "lattice"

# Substation
GET {{base_url}}/feature/openrailwaymap_electrification/electrification_substation/320522867
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.note" == null
jsonpath "$.description" == null
jsonpath "$.osm_id" == 320522867
jsonpath "$.osm_type" == "W"
jsonpath "$.voltage" count == 2
jsonpath "$.voltage[0]" == "30000"
jsonpath "$.voltage[1]" == "750"

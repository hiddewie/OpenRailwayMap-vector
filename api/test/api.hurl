# Status
GET {{base_url}}/status
HTTP 200

# Replication timestamp
GET {{base_url}}/replication_timestamp
HTTP 200

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
jsonpath "$[2].name" == "Hauptbahnhof"
jsonpath "$[3].name" == "Berlin Hauptbahnhof"
jsonpath "$[4].name" == "Berlin Südkreuz"
jsonpath "$[5].name" == "Südkreuz (Nord-Süd)"
jsonpath "$[6].name" == "Südkreuz (Ringbahn)"
jsonpath "$[7].name" == "Berlin-Spandau"
jsonpath "$[8].name" == "Spandau"
jsonpath "$[9].name" == "Berlin Ostbahnhof"
jsonpath "$[10].name" == "Ostbahnhof"
jsonpath "$[11].name" == "Ostkreuz (Ringbahn)"
jsonpath "$[12].name" == "Gesundbrunnen"
jsonpath "$[13].name" == "Berlin Ostkreuz (Ringbahn-F)"
jsonpath "$[14].name" == "Ostkreuz"
jsonpath "$[15].name" == "Berlin Ostkreuz (Stadtbahn-F)"
jsonpath "$[16].name" == "Berlin Gesundbrunnen"
jsonpath "$[17].name" == "Berlin Ostkreuz (Ostbahn)"
jsonpath "$[18].name" == "Alexanderplatz"
jsonpath "$[19].name" == "Berlin Alexanderplatz"

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

# Facility request with with diacritics
GET {{base_url}}/facility
[QueryStringParams]
name: Karl-Marx-Straße
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Karl-Marx-Straße"

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

# Facility search for UIC reference
GET {{base_url}}/facility
[QueryStringParams]
uic_ref: 8089028
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].name" == "Ostkreuz"
jsonpath "$[1].name" == "Ostkreuz (Ringbahn)"

# Facility search for name, reference or UIC reference
GET {{base_url}}/facility
[QueryStringParams]
q: BOK
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Ostkreuz (Ringbahn)"

# Facility search for name, reference or UIC reference
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

# Facility search for name, reference or UIC reference
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].name" == "Ostkreuz"
jsonpath "$[1].name" == "Ostkreuz (Ringbahn)"

# Facility search for name, reference or UIC reference for grouped station
GET {{base_url}}/facility
[QueryStringParams]
q: Landsberger Allee
HTTP 200
[Asserts]
jsonpath "$" count == 3
jsonpath "$[0].name" == "Landsberger Allee/Petersburger Straße"
jsonpath "$[0].feature" == "tram_stop"
jsonpath "$[0].state" == "present"
jsonpath "$[0].rank" == 32
jsonpath "$[0].osm_ids" count == 4
jsonpath "$[0].osm_ids[0]" == 244129991
jsonpath "$[0].osm_ids[1]" == 271777826
jsonpath "$[0].osm_ids[2]" == 1679221136
jsonpath "$[0].osm_ids[3]" == 1787945074
jsonpath "$[0].osm_types" count == 4
jsonpath "$[2].railway_ref" == "BLST"
jsonpath "$[2].station" == "light_rail"
jsonpath "$[2].uic_ref" == "8089020"
jsonpath "$[2].operator[0]" == "DB InfraGO AG"
jsonpath "$[2].network[0]" == "Verkehrsverbund Berlin-Brandenburg"
jsonpath "$[2].wikidata[0]" == "Q800507"
jsonpath "$[2].wikipedia[0]" == "de:Bahnhof Berlin Landsberger Allee"

# Facility request missing required parameter
GET {{base_url}}/facility
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "No argument with a search term provided."
jsonpath "$.detail.detail" == "Provide one of the following query parameters: q, name, ref, uic_ref"

# Facility request duplicated search parameters (1)
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref, uic_ref"

# Facility request duplicated search parameters (2)
GET {{base_url}}/facility
[QueryStringParams]
q: 8089028
uic_ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref, uic_ref"

# Facility request duplicated search parameters (3)
GET {{base_url}}/facility
[QueryStringParams]
name: 8089028
uic_ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref, uic_ref"

# Facility request duplicated search parameters (4)
GET {{base_url}}/facility
[QueryStringParams]
q: test
name: test
ref: test
uic_ref: test
HTTP 422
[Asserts]
jsonpath "$.detail.error" == "More than one argument with a search term provided."
jsonpath "$.detail.detail" == "Provide only one of the following query parameters: q, name, ref, uic_ref"

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

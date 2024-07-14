# Facility request
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$" count == 20
jsonpath "$[0].name" == "Berlin Südkreuz"
jsonpath "$[1].name" == "Berlin-Spandau"
jsonpath "$[2].name" == "Berlin Gesundbrunnen"
jsonpath "$[3].name" == "Berlin Ostbahnhof"
jsonpath "$[4].name" == "Berlin Hauptbahnhof"
jsonpath "$[5].name" == "Ostkreuz"
jsonpath "$[6].name" == "Berlin Potsdamer Platz"
jsonpath "$[7].name" == "Warschauer Straße"
jsonpath "$[8].name" == "Bornholmer Straße"
jsonpath "$[9].name" == "Baumschulenweg"
jsonpath "$[10].name" == "Schöneweide"
jsonpath "$[11].name" == "Alexanderplatz"
jsonpath "$[12].name" == "Gesundbrunnen"
jsonpath "$[13].name" == "Berlin Alexanderplatz"
jsonpath "$[14].name" == "Berlin Zoologischer Garten"
jsonpath "$[15].name" == "Zoologischer Garten"
jsonpath "$[16].name" == "Ostbahnhof"
jsonpath "$[17].name" == "Westkreuz"
jsonpath "$[18].name" == "Brandenburger Tor"
jsonpath "$[19].name" == "Berlin Friedrichstraße"

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

# TODO request with too large limit

# Facility request with hyphen
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin-Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 7
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Berlin-Spandau Gbf"
jsonpath "$[3].name" == "Berlin-Spandau West"
jsonpath "$[4].name" == "Berlin-Spandau Mitte"
jsonpath "$[5].name" == "Berlin-Spandau Ost"
jsonpath "$[6].name" == "Berlin-Spandau Johannesstift"

# Facility request with space
GET {{base_url}}/facility
[QueryStringParams]
name: Berlin Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 7
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Berlin-Spandau Gbf"
jsonpath "$[3].name" == "Berlin-Spandau West"
jsonpath "$[4].name" == "Berlin-Spandau Mitte"
jsonpath "$[5].name" == "Berlin-Spandau Ost"
jsonpath "$[6].name" == "Berlin-Spandau Johannesstift"

# Facility request for Spandau
GET {{base_url}}/facility
[QueryStringParams]
name: Spandau
HTTP 200
[Asserts]
jsonpath "$" count == 9
jsonpath "$[0].name" == "Berlin-Spandau"
jsonpath "$[1].name" == "Spandau"
jsonpath "$[2].name" == "Altstadt Spandau"
jsonpath "$[3].name" == "Rathaus Spandau"
jsonpath "$[4].name" == "Berlin-Spandau Gbf"
jsonpath "$[5].name" == "Berlin-Spandau West"
jsonpath "$[6].name" == "Berlin-Spandau Mitte"
jsonpath "$[7].name" == "Berlin-Spandau Ost"
jsonpath "$[8].name" == "Berlin-Spandau Johannesstift"

# Facility request with with diacritics
GET {{base_url}}/facility
[QueryStringParams]
name: Karl-Marx-Straße
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].name" == "Karl-Marx-Straße"

# TODO facility request with q query
# TODO facility request with UIC queries

# Milestone request for line 6020 milestone 22.7
GET {{base_url}}/milestone
[QueryStringParams]
ref: 6020
position: 22.7
limit: 1
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].ref" == "6020"
jsonpath "$[0].position" == 22.7

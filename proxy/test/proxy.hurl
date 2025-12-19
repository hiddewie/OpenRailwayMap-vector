# Hmoe page
GET {{base_url}}/
HTTP 200
Content-Type: text/html
[Asserts]
body contains "<title>OpenRailwayMap</title>"

# News
GET {{base_url}}/news.html
HTTP 200
Content-Type: text/html
[Asserts]
body contains "<em class=\"flex-fill\">April 2025</em>"
header "X-Content-Hash" matches "^[0-9a-f]{40}$"

# Manifest
GET {{base_url}}/manifest.json
HTTP 200
Content-Type: application/json

# Proxy to tiles
GET {{base_url}}/railway_line_high
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard_railway_text_stations_low
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard_railway_text_stations_med
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard_railway_turntables,standard_railway_text_stations,standard_railway_grouped_stations,standard_railway_grouped_station_areas,standard_railway_symbols,standard_railway_switch_ref,standard_station_entrances,standard_railway_platforms,standard_railway_platform_edges,standard_railway_stop_positions
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/speed_railway_signals
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/signals_railway_signals,signals_signal_boxes
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/electrification_signals,electrification_catenary,electrification_railway_symbols,electrification_substation
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

GET {{base_url}}/operator_railway_symbols
Referer: http://localhost:8000
HTTP 200
Content-Type: application/json

# (local URLs)
GET {{base_url}}/signals_railway_signals,signals_signal_boxes/14/8803/5371
Referer: http://localhost:8000
HTTP 200
Content-Type: application/x-protobuf

GET {{base_url}}/signals_railway_signals,signals_signal_boxes/18/140807/85974
Referer: http://localhost:8000
HTTP 204

# Proxy to API, cannot proxy
GET {{base_url}}/api/test
HTTP 404

# Proxy to sprites
GET {{base_url}}/sprite/symbols.json
HTTP 200
Content-Type: application/json

GET {{base_url}}/sprite/symbols.png
HTTP 200

# Proxy to SDF sprites
GET {{base_url}}/sdf_sprite/symbols.json
HTTP 200
Content-Type: application/json

# Features
GET {{base_url}}/features.json
HTTP 200
Content-Type: application/json

# JOSM preset
GET {{base_url}}/preset.zip
HTTP 200
Content-Type: application/zip

# Taginfo
GET {{base_url}}/taginfo.json
HTTP 200
Content-Type: application/json
[Asserts]
jsonpath "$.data_format" == 1
jsonpath "$.data_url" == "https://openrailwaymap.app/taginfo.json"
jsonpath "$.project.name" == "OpenRailwayMap-vector"
jsonpath "$.tags[*].key" includes "name"
jsonpath "$.tags[*].key" includes "railway"

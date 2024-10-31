GET {{base_url}}/
HTTP 200
Content-Type: text/plain; charset=utf-8

GET {{base_url}}/catalog
HTTP 200

# Tile sources
GET {{base_url}}/railway_line_low
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard_railway_text_stations_low
HTTP 200
Content-Type: application/json

GET {{base_url}}/railway_line_med
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard_railway_text_stations_med
HTTP 200
Content-Type: application/json

GET {{base_url}}/high
HTTP 200
Content-Type: application/json

GET {{base_url}}/standard
HTTP 200
Content-Type: application/json

GET {{base_url}}/speed
HTTP 200
Content-Type: application/json

GET {{base_url}}/signals
HTTP 200
Content-Type: application/json

GET {{base_url}}/electrification
HTTP 200
Content-Type: application/json

GET {{base_url}}/speed/14/8803/5371
Referer: http://localhost:8000
HTTP 200
Content-Type: application/x-protobuf

GET {{base_url}}/speed/18/140807/85974
Referer: http://localhost:8000
HTTP 204

# Sprites
GET {{base_url}}/sprite/symbols.json
HTTP 200
Content-Type: application/json

GET {{base_url}}/sprite/symbols.png
HTTP 200

# SDF sprites
GET {{base_url}}/sdf_sprite/symbols.json
HTTP 200
Content-Type: application/json

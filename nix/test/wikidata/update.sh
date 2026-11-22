#!/usr/bin/env nix
#! nix --extra-experimental-features nix-command --extra-experimental-features flakes
#! nix shell --inputs-from ../../.. nixpkgs#bash nixpkgs#curl nixpkgs#jq --command bash
# Refresh the recorded www.wikidata.org responses that the NixOS VM test
# (nix/checks.nix) serves to the API instead of the real site, then commit the
# changed JSON files. It runs with curl and jq from the flake's nixpkgs.
set -euo pipefail
cd "$(dirname "$0")"

fetch() {
  curl -fsSL -H 'accept: application/json' -o "$1" "$2"
}

imageinfo() {
  fetch "$1" "https://www.wikidata.org/w/api.php?action=query&prop=imageinfo&iiprop=extmetadata&titles=$(jq -rn --arg f "File:$2" '$f | @uri')&format=json"
}

# WikidataAPI.wikidata_image_file: P18 statements of the item
fetch statements-Q660045.json \
  'https://www.wikidata.org/w/rest.php/wikibase/v1/entities/items/Q660045/statements?property=P18'

# WikidataAPI.wikimedia_file_attribution: extmetadata of the item's image, the
# best ranked one as the API picks it, and of the file an OSM object names
imageinfo imageinfo-ostkreuz.json \
  "$(jq -r '.P18 | max_by(.rank) | .value.content' statements-Q660045.json)"
imageinfo imageinfo-wuhletal.json 'U-Bahnhof Wuhletal.jpg'

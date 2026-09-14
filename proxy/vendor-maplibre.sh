#!/usr/bin/env bash
# Vendor a MapLibre GL JS release from npm into proxy/js and proxy/css.
#
#   proxy/vendor-maplibre.sh 6.9.0
#
# The files are copied unchanged from the `maplibre-gl` package's dist/, so a reviewer can
# re-run this for the vendored version and see `git status` stay clean. Update the paths in
# proxy/index.html when the version changes.
set -euo pipefail

version=$1
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cd "$tmp"
npm pack --silent "maplibre-gl@$version" > /dev/null
tar xzf "maplibre-gl-$version.tgz"

js="$here/js/maplibre-gl-$version"
css="$here/css/maplibre-gl-$version"
rm -rf "$js" "$css"
mkdir -p "$js" "$css"
for file in maplibre-gl.mjs maplibre-gl-shared.mjs maplibre-gl-worker.mjs; do
  cp "package/dist/$file" "package/dist/$file.map" "$js/"
done
cp package/dist/maplibre-gl.css "$css/"
cp package/LICENSE.txt "$js/"
cp package/LICENSE.txt "$css/"

echo "Vendored maplibre-gl $version (npm integrity $(npm view --silent "maplibre-gl@$version" dist.integrity))"

# Everything the Dockerfiles generate from features/*.yaml at build time:
# the osm2pgsql Lua tag tables, SQL for signals and operators, the MapLibre
# style, legend, taginfo and the JOSM preset, and the API feature catalogue.
{
  stdenvNoCC,
  nodejs,
  python3,
  zip,
  src,
  node-deps,
  presetVersion ? "nix",
}:
stdenvNoCC.mkDerivation {
  pname = "openrailwaymap-generated";
  version = presetVersion;
  inherit src;
  nativeBuildInputs = [
    nodejs
    zip
    (python3.withPackages (ps: [
      ps.pyyaml
      ps.yattag
    ]))
  ];

  # The generators read their inputs by relative path, some flat next to the
  # script and some under features/, so work from a copy of the tree with
  # node_modules linked in and mirror each Dockerfile's working directory.
  buildPhase = ''
    ln -s ${node-deps}/node_modules node_modules
    mkdir -p gen/sql

    mkdir flat
    cp features/train_protection.yaml features/signals_railway_signals.yaml features/poi.yaml \
       features/stations.yaml features/track_class.yaml features/operators.yaml flat/
    ln -s ../symbols flat/symbols
    ln -s ../node_modules flat/node_modules
    ( cd flat && node ../import/tags.lua.mjs > ../gen/tags.lua )
    ( cd flat && node ../import/sql/signal_features.sql.mjs > ../gen/sql/signal_features.sql )
    ( cd flat && node ../import/sql/operators.sql.mjs > ../gen/sql/operators.sql )

    node proxy/js/styles.mjs > gen/style.json
    node proxy/js/legend.mjs > gen/legend.json
    node proxy/js/taginfo.mjs > gen/taginfo.json
    node api/features.mjs > gen/features.json

    PRESET_VERSION=${presetVersion} python3 proxy/preset.py > gen/preset.xml
    ( cd gen && ln -s ../symbols symbols && zip -o preset.zip -r -q symbols preset.xml && rm symbols )
  '';

  installPhase = ''
    mkdir -p $out
    cp -r gen/. $out/
  '';
}

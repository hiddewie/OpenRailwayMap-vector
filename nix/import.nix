# import/import.sh with its container paths replaced: the OSM data
# lives under $ORM_DATA, and the Lua/SQL/filter files come from the store.
{
  writeShellApplication,
  runCommand,
  osm2pgsql,
  osmium-tool,
  python3,
  postgresql_19,
  gdal,
  src,
  generated,
}:
let
  # osm2pgsql resolves `require('tags')` relative to the working directory,
  # so assemble one directory with the style, generated tags and SQL.
  importDir = runCommand "openrailwaymap-import-dir" { } ''
    mkdir -p $out/sql
    cp ${src}/import/openrailwaymap.lua ${src}/import/osmium-tags-filter $out/
    cp ${generated}/tags.lua $out/
    cp ${src}/import/sql/*.sql $out/sql/
    cp ${generated}/sql/*.sql $out/sql/
  '';
  # The script is used verbatim apart from the /data prefix.
  script = runCommand "orm-import-script" { } ''
    sed -e 's|"/data/|"$ORM_DATA/|g' ${src}/import/import.sh > $out
  '';
in
writeShellApplication {
  name = "orm-import";
  runtimeInputs = [
    osm2pgsql
    osmium-tool
    python3.pkgs.osmium
    postgresql_19
    gdal
  ];
  text = ''
    ORM_DATA="$(realpath "''${ORM_DATA:-./data}")"
    export ORM_DATA
    export PGHOST="''${PGHOST:-localhost}"
    export PGPORT="''${PGPORT:-5433}"
    export PGUSER="''${PGUSER:-postgres}"
    cd ${importDir}
    # shellcheck disable=SC1090,SC1091
    source ${script} "$@"
  '';
}

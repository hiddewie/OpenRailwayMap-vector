# The FastAPI application, run with uvicorn (what `fastapi run` wraps).
{
  writeShellApplication,
  runCommand,
  python3,
  src,
  generated,
}:
let
  python = python3.withPackages (ps: [
    ps.fastapi
    ps.asyncpg
    ps.httpx
    ps.uvicorn
  ]);
  appDir = runCommand "openrailwaymap-api-dir" { } ''
    mkdir -p $out/static
    cp -r ${src}/api/api.py ${src}/api/openrailwaymap_api $out/
    cp ${generated}/features.json $out/static/features.json
  '';
in
writeShellApplication {
  name = "orm-api";
  runtimeInputs = [ python ];
  text = ''
    export POSTGRES_USER="''${POSTGRES_USER:-postgres}"
    export POSTGRES_HOST="''${POSTGRES_HOST:-''${PGHOST:-localhost}}"
    export POSTGRES_DB="''${POSTGRES_DB:-gis}"
    export PGPORT="''${PGPORT:-5433}"
    cd ${appDir}
    exec uvicorn api:app --host "''${HOST:-127.0.0.1}" --port "''${PORT:-5002}" "$@"
  '';
}

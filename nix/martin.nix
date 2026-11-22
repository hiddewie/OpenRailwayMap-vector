# The Martin tile server with the repo's function-source config and the
# symbol sprites, exactly as martin.Dockerfile runs it.
{
  writeShellApplication,
  martin,
  src,
}:
writeShellApplication {
  name = "orm-martin";
  runtimeInputs = [ martin ];
  text = ''
    export DATABASE_URL="''${DATABASE_URL:-postgresql://postgres@''${PGHOST:-localhost}:''${PGPORT:-5433}/gis}"
    export POSTGRES_RELOAD_INTERVAL="''${POSTGRES_RELOAD_INTERVAL:-10s}"
    exec martin --config ${src}/martin/configuration.yml --sprite ${src}/symbols \
      --listen-addresses "''${MARTIN_LISTEN:-127.0.0.1:3001}" "$@"
  '';
  # nixpkgs' Martin is Linux only (it links a prebuilt maplibre-native), and
  # so is this wrapper; on macOS install Martin some other way.
  #
  # @Ericson2314 am working on getting Nixpkgs to build it from source instead,
  # but that is orhtogonal to this PR.
  meta.platforms = martin.meta.platforms;
}

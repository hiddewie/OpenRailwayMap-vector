# The static site and the nginx server block from proxy.conf.template.
# The template is rendered at build time with the same variables the
# container fills in at start; the TLS listeners and /etc/nginx paths are
# rewritten since NixOS's nginx handles TLS and paths itself, and
# X-Rewrite-URL uses the raw $request_uri, which cannot carry decoded
# newlines (NixOS lints the config with gixy and rejects $uri there).
{
  runCommand,
  gettext,
  nginx,
  src,
  generated,
}:
let
  public = runCommand "openrailwaymap-public" { } ''
    mkdir -p $out
    cp -r ${src}/proxy/{manifest.json,index.html,news.html,api,js,css,image,font} $out/
    cp ${generated}/{style.json,legend.json,taginfo.json,preset.zip} $out/
  '';
  # The values default to compose.yaml's development settings.
  serverConf =
    {
      port ? 8000,
      tilesUpstream ? "127.0.0.1:3001",
      apiUpstream ? "127.0.0.1:5002",
      publicProtocol ? "http",
      publicHost ? null, # null: whatever Host the request came in with
      nginxCacheTtl ? 0,
      clientCacheTtl ? {
        assetsFresh = 0;
        assetsStale = 0;
        apiFresh = 0;
        apiStale = 0;
        tilesFresh = 0;
        tilesStale = 0;
        notFound = 0;
      },
      cacheDir ? "/var/cache/nginx/",
      resolver ? "127.0.0.1",
      serverName ? "localhost",
    }:
    runCommand "openrailwaymap-server.conf"
      {
        nativeBuildInputs = [ gettext ];
        NGINX_RESOLVER = resolver;
        NGINX_CACHE_DIR = cacheDir;
        PROXY_PORT = toString port;
        TILES_UPSTREAM = tilesUpstream;
        API_UPSTREAM = apiUpstream;
        PUBLIC_PROTOCOL = publicProtocol;
        # Martin builds absolute tile URLs from X-Forwarded-Host, so with no fixed
        # public host forward the request's own (nginx expands $http_host at request time).
        PUBLIC_HOST = if publicHost == null then "$http_host" else publicHost;
        NGINX_CACHE_TTL = toString nginxCacheTtl;
        CLIENT_CACHE_TTL_ASSETS_FRESH = toString clientCacheTtl.assetsFresh;
        CLIENT_CACHE_TTL_ASSETS_STALE = toString clientCacheTtl.assetsStale;
        CLIENT_CACHE_TTL_API_FRESH = toString clientCacheTtl.apiFresh;
        CLIENT_CACHE_TTL_API_STALE = toString clientCacheTtl.apiStale;
        CLIENT_CACHE_TTL_TILES_FRESH = toString clientCacheTtl.tilesFresh;
        CLIENT_CACHE_TTL_TILES_STALE = toString clientCacheTtl.tilesStale;
        CLIENT_CACHE_TTL_NOT_FOUND = toString clientCacheTtl.notFound;
        SERVER_NAME = serverName;
      }
      ''
        NEWS_HASH="$(grep '<h5>' ${public}/news.html | sha1sum - | awk '{print $1}')"
        export NEWS_HASH
        sed -e '/listen .*443/d' \
            -e 's|X-Rewrite-URL $uri;|X-Rewrite-URL $request_uri;|' \
            -e '/ssl_certificate/d' \
            -e 's|/etc/nginx/public|${public}|g' \
            -e 's|include mime.types;|include ${nginx}/conf/mime.types;|' \
            -e 's|proxy_cache_path /var/cache/nginx/|proxy_cache_path ''${NGINX_CACHE_DIR}|' \
            -e 's|listen 8000 default_server|listen ''${PROXY_PORT} default_server|' \
            -e 's|listen \[::\]:8000|listen [::]:''${PROXY_PORT}|' \
            -e 's|server_name localhost;|server_name ''${SERVER_NAME};|' \
            ${src}/proxy/proxy.conf.template \
          | envsubst '$NGINX_RESOLVER $NGINX_CACHE_DIR $PROXY_PORT $TILES_UPSTREAM $API_UPSTREAM $PUBLIC_PROTOCOL $PUBLIC_HOST $NGINX_CACHE_TTL $NEWS_HASH $SERVER_NAME $CLIENT_CACHE_TTL_ASSETS_FRESH $CLIENT_CACHE_TTL_ASSETS_STALE $CLIENT_CACHE_TTL_API_FRESH $CLIENT_CACHE_TTL_API_STALE $CLIENT_CACHE_TTL_TILES_FRESH $CLIENT_CACHE_TTL_TILES_STALE $CLIENT_CACHE_TTL_NOT_FOUND' \
          > $out
      '';
in
{
  inherit public serverConf;
}

# NixOS module: the whole OpenRailwayMap stack as ordinary NixOS services.
# PostgreSQL and nginx are the stock NixOS services; import, Martin and the
# API are systemd units around the wrapper scripts from ./default.nix.
{ orm, src }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.openrailwaymap;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  pgSocket = "/run/postgresql";
  pgPort = toString config.services.postgresql.settings.port;
  # environment the wrapper scripts use to reach the database as the service user
  dbEnv = {
    ORM_DATA = cfg.dataDir;
    PGHOST = pgSocket;
    PGPORT = pgPort;
    PGUSER = cfg.user;
    PGDATABASE = "gis";
  };
in
{
  options.services.openrailwaymap = {
    enable = mkEnableOption "OpenRailwayMap vector tile server, API and web site";

    user = mkOption {
      type = types.str;
      default = "openrailwaymap";
      description = "System user the import, Martin and API run as (also the database owner).";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/openrailwaymap";
      description = "Where the OSM data file and its filtered copy are kept.";
    };

    osmFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "OSM extract to import (copied to dataDir on first import). Alternative to osmDownloadUrl.";
    };

    osmDownloadUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://download.geofabrik.de/north-america/us/new-york-latest.osm.pbf";
      description = "URL of the OSM extract to download before the first import, if no data file is present.";
    };

    importProcesses = mkOption {
      type = types.int;
      default = 4;
      description = "osm2pgsql --number-processes.";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port nginx serves the site, tiles and API on.";
    };

    serverName = mkOption {
      type = types.str;
      default = "localhost";
      description = "nginx server_name.";
    };

    publicHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "openrailwaymap.app";
      description = ''
        Host (with port if not default) the site is reached at, sent to Martin and the API
        as X-Forwarded-Host so that tile URLs point back at it. By default the Host of each
        request is forwarded, which works for any address the server is reached on; set it
        when a CDN or reverse proxy in front rewrites the Host header.
      '';
    };

    publicProtocol = mkOption {
      type = types.enum [
        "http"
        "https"
      ];
      default = "http";
      description = "Protocol the site is reached with. Terminate TLS in front of nginx and set https here.";
    };

    martinPort = mkOption {
      type = types.port;
      default = 3001;
      description = "Local port Martin listens on.";
    };
    apiPort = mkOption {
      type = types.port;
      default = 5002;
      description = "Local port the API listens on.";
    };

    nginxCacheTtl = mkOption {
      type = types.int;
      default = 86400;
      description = "Seconds nginx caches tiles and API responses; production uses 86400, development 0.";
    };

    clientCacheTtl = mkOption {
      type = types.attrsOf types.int;
      default = {
        assetsFresh = 3600;
        assetsStale = 604800;
        apiFresh = 8182;
        apiStale = 604800;
        tilesFresh = 8182;
        tilesStale = 604800;
        notFound = 600;
      };
      description = "Client Cache-Control max-age / stale-if-error seconds, as in the production compose.override.yaml.";
    };

    update = {
      enable = mkEnableOption "the daily OSM data update and re-import" // {
        default = true;
      };
      onCalendar = mkOption {
        type = types.str;
        default = "*-*-* 08:00:00";
        description = "systemd calendar expression for the update.";
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open `port` in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.osmFile != null || cfg.osmDownloadUrl != null;
        message = "services.openrailwaymap needs osmFile or osmDownloadUrl to know what to import.";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.dataDir;
    };
    users.groups.${cfg.user} = { };

    # --- Database: db/Dockerfile's init scripts, as a NixOS PostgreSQL instance -----------------
    services.postgresql = {
      enable = true;
      # PostgreSQL 19, as db/Dockerfile's image has since upstream's #1184.
      package = pkgs.postgresql_19;
      extensions = ps: [ ps.postgis ];
      # db/tune-postgis.sh
      settings = {
        work_mem = lib.mkDefault "50MB";
        maintenance_work_mem = lib.mkDefault "2GB";
        autovacuum_work_mem = lib.mkDefault "1GB";
        shared_buffers = lib.mkDefault "1GB";
        wal_level = lib.mkDefault "minimal";
        max_wal_senders = lib.mkDefault 0;
        checkpoint_timeout = lib.mkDefault "60min";
        random_page_cost = lib.mkDefault 0.1;
      };
      # The service role is a superuser like `postgres` in the container: the
      # import SQL defines LEAKPROOF functions, which nothing less may create.
      initialScript = pkgs.writeText "openrailwaymap-init.sql" ''
        CREATE ROLE "${cfg.user}" LOGIN SUPERUSER;
        CREATE DATABASE gis OWNER "${cfg.user}";
        \connect gis
        CREATE EXTENSION IF NOT EXISTS postgis;
        \i ${src}/db/extensions.sql
        SET ROLE "${cfg.user}";
        \i ${src}/db/types.sql
        \i ${src}/db/operators.sql
      '';
    };

    # --- Import: once at first boot, then on the update timer ---------------------------------
    systemd.services.openrailwaymap-import = {
      description = "OpenRailwayMap initial OSM import";
      wantedBy = [ "multi-user.target" ];
      after = [
        "postgresql.service"
        "network-online.target"
      ];
      requires = [ "postgresql.service" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = "!${cfg.dataDir}/.imported";
      environment = dbEnv // {
        OSM2PGSQL_NUMPROC = toString cfg.importProcesses;
      };
      path = [ pkgs.curl ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.user;
        StateDirectory = lib.mkIf (cfg.dataDir == "/var/lib/openrailwaymap") "openrailwaymap";
        WorkingDirectory = cfg.dataDir;
        TimeoutStartSec = "infinity";
      };
      script = ''
        if [[ ! -f data.osm.pbf ]]; then
      ''
      + lib.optionalString (cfg.osmFile != null) ''
        cp ${cfg.osmFile} data.osm.pbf
      ''
      + lib.optionalString (cfg.osmFile == null) ''
        curl -fsSL -o data.osm.pbf.tmp ${lib.escapeShellArg cfg.osmDownloadUrl}
        mv data.osm.pbf.tmp data.osm.pbf
      ''
      + ''
        fi
        ${orm.orm-import}/bin/orm-import import
        touch .imported
      '';
    };

    systemd.services.openrailwaymap-update = mkIf cfg.update.enable {
      description = "OpenRailwayMap OSM data update and re-import";
      after = [
        "postgresql.service"
        "openrailwaymap-import.service"
        "network-online.target"
      ];
      requires = [ "postgresql.service" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = "${cfg.dataDir}/.imported";
      environment = dbEnv // {
        OSM2PGSQL_NUMPROC = toString cfg.importProcesses;
      };
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.dataDir;
        TimeoutStartSec = "infinity";
      };
      # Same as deployment/update.sh: pull replication diffs into the filtered
      # file, then re-import. Martin serves stale tiles from its pool meanwhile;
      # restarting it afterwards clears any cached table bounds.
      script = ''
        ${orm.orm-import}/bin/orm-import update
        ${orm.orm-import}/bin/orm-import import
      '';
      postStop = "systemctl restart openrailwaymap-martin.service openrailwaymap-api.service";
    };

    systemd.timers.openrailwaymap-update = mkIf cfg.update.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.update.onCalendar;
        Persistent = true;
      };
    };

    # --- Tile server and API ---------------------------------------------------------------------
    systemd.services.openrailwaymap-martin = {
      description = "OpenRailwayMap tile server (Martin)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "postgresql.service"
        "openrailwaymap-import.service"
      ];
      requires = [ "postgresql.service" ];
      wants = [ "openrailwaymap-import.service" ];
      environment = {
        DATABASE_URL = "postgresql://${cfg.user}@/gis?host=${pgSocket}&port=${pgPort}";
        MARTIN_LISTEN = "127.0.0.1:${toString cfg.martinPort}";
      };
      serviceConfig = {
        ExecStart = "${orm.orm-martin}/bin/orm-martin";
        User = cfg.user;
        Group = cfg.user;
        Restart = "always";
        RestartSec = 5;
        LimitNOFILE = 46677;
      };
    };

    systemd.services.openrailwaymap-api = {
      description = "OpenRailwayMap API";
      wantedBy = [ "multi-user.target" ];
      after = [
        "postgresql.service"
        "openrailwaymap-import.service"
      ];
      requires = [ "postgresql.service" ];
      wants = [ "openrailwaymap-import.service" ];
      environment = {
        POSTGRES_USER = cfg.user;
        POSTGRES_HOST = pgSocket;
        PGPORT = pgPort;
        POSTGRES_DB = "gis";
        HOST = "127.0.0.1";
        PORT = toString cfg.apiPort;
      };
      serviceConfig = {
        ExecStart = "${orm.orm-api}/bin/orm-api";
        User = cfg.user;
        Group = cfg.user;
        Restart = "always";
        RestartSec = 5;
      };
    };

    # --- Web: the upstream server block inside NixOS's nginx ------------------------------------
    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        include ${
          orm.serverConf {
            inherit (cfg)
              port
              publicProtocol
              publicHost
              nginxCacheTtl
              clientCacheTtl
              serverName
              ;
            tilesUpstream = "127.0.0.1:${toString cfg.martinPort}";
            apiUpstream = "127.0.0.1:${toString cfg.apiPort}";
            cacheDir = "/var/cache/nginx/openrailwaymap/";
          }
        };
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}

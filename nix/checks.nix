# `nix flake check`: what the old GitHub workflow did with containers.
{
  pkgs,
  lib,
  src,
  orm,
  nixosModule,
  # The extract to import, a flake input.
  berlin,
}:
let
  # The API's /wikidata and /wikimedia endpoints call www.wikidata.org, which
  # the sandboxed test container cannot reach. The responses the test suite depends
  # on are checked in under nix/test/wikidata (refresh them with the update
  # script there) and served inside the container by a plain-HTTP nginx virtual host
  # that the API is pointed at with WIKIDATA_BASE_URL (see below).
  wikidata = "${src}/nix/test/wikidata";
  wikidataPort = 8081;

  # The Cypress UI tests (proxy/test/ui), as the old workflow ran them with
  # cypress-io/github-action. The app is nixpkgs' build; its bundled Electron
  # is past its support and so marked insecure, which is acceptable for driving
  # the local test site in the sandboxed container, and only here.
  cypress = pkgs.cypress.overrideAttrs (old: {
    meta = old.meta // {
      knownVulnerabilities = [ ];
    };
  });
  # The cypress command from proxy/test/ui's lock file, without the app it
  # would download; it runs nixpkgs' app (a newer 15.x, which it warns about).
  uiTestDeps = pkgs.buildNpmPackage {
    pname = "openrailwaymap-ui-test-deps";
    version = "0.0.0";
    src = pkgs.runCommand "openrailwaymap-ui-test-manifest" { } ''
      mkdir $out
      cp ${src}/proxy/test/ui/package.json ${src}/proxy/test/ui/package-lock.json $out/
    '';
    npmDepsHash = "sha256-BgVg0eL1P2RdMz1RUUKj9TBFHILI8TUaNdiNf9255fM=";
    env.CYPRESS_INSTALL_BINARY = "0";
    dontNpmBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';
  };
  # The npm packages of the feature schema test, from features/test's lock file.
  featureTestDeps = pkgs.buildNpmPackage {
    pname = "openrailwaymap-feature-test-deps";
    version = "0.0.0";
    src = pkgs.runCommand "openrailwaymap-feature-test-manifest" { } ''
      mkdir $out
      cp ${src}/features/test/package.json ${src}/features/test/package-lock.json $out/
    '';
    npmDepsHash = "sha256-/IcWZl6LbsHpqvMnzhcWf+3hur9aOxWWUUdvqmEIcDo=";
    dontNpmBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';
  };
  # Runs them against the site on localhost:8000 (cypress.config.js), from a
  # writable copy, as Cypress writes screenshots next to the tests, under
  # xvfb-run for Electron's display: left to start Xvfb itself, Cypress ran
  # Electron without one.
  uiTests = pkgs.writeShellScript "openrailwaymap-ui-tests" ''
    set -eu
    export PATH=${
      lib.makeBinPath [
        pkgs.nodejs
        pkgs.xvfb-run
      ]
    }:$PATH
    export CYPRESS_RUN_BINARY=${cypress}/bin/Cypress
    cp -r ${src}/proxy/test/ui "$HOME/ui"
    chmod -R u+w "$HOME/ui"
    ln -s ${uiTestDeps}/node_modules "$HOME/ui/node_modules"
    cd "$HOME/ui"
    exec xvfb-run --auto-servernum ./node_modules/.bin/cypress run --browser electron --config video=false
  '';
in
{
  # import/Dockerfile's `test` stage: the Lua tag logic against the generated tables
  import-test =
    pkgs.runCommand "openrailwaymap-import-test" { nativeBuildInputs = [ pkgs.lua5_4 ]; }
      ''
        cp -r ${src}/import/test test
        cp ${src}/import/openrailwaymap.lua ${orm.generated}/tags.lua .
        lua test/test_all.lua
        touch $out
      '';

  # features/test/test.js: every features/*.yaml against its JSON schema, with
  # the script's own npm packages (ajv, yaml), which it finds next to itself.
  # It reads the features from its working directory, so it runs from a copy
  # of features/ with node_modules linked in.
  feature-test =
    pkgs.runCommand "openrailwaymap-feature-test" { nativeBuildInputs = [ pkgs.nodejs ]; }
      ''
        cp -r ${src}/features features
        chmod -R u+w features
        ln -s ${featureTestDeps}/node_modules features/test/node_modules
        cd features
        node test/test.js
        touch $out
      '';

  formatting =
    (pkgs.treefmt.withConfig {
      runtimeInputs = [ pkgs.gitMinimal ];
      settings.formatter.nixfmt = {
        command = lib.getExe pkgs.nixfmt;
        includes = [ "*.nix" ];
      };
    }).check
      src;

  # The whole stack in a NixOS systemd-nspawn container with the Berlin
  # extract, then the API, proxy and UI test suites against it, as the old
  # workflow did with Compose.
  container-test = pkgs.testers.runNixOSTest {
    name = "openrailwaymap";
    containers.machine = {
      imports = [ nixosModule ];
      services.openrailwaymap = {
        enable = true;
        osmFile = berlin;
        nginxCacheTtl = 0;
        clientCacheTtl = lib.genAttrs [
          "assetsFresh"
          "assetsStale"
          "apiFresh"
          "apiStale"
          "tilesFresh"
          "tilesStale"
          "notFound"
        ] (_: 0);
        update.enable = false;
      };
      environment.systemPackages = [ pkgs.hurl ];
      # Electron refuses to run as root
      users.users.ui-test.isNormalUser = true;

      # a stand-in for www.wikidata.org serving the recorded responses
      systemd.services.openrailwaymap-api.environment.WIKIDATA_BASE_URL =
        "http://127.0.0.1:${toString wikidataPort}";
      services.nginx.appendHttpConfig = ''
        map $arg_titles $wikidata_imageinfo {
          ~Ostkreuz ${wikidata}/imageinfo-ostkreuz.json;
          ~Wuhletal ${wikidata}/imageinfo-wuhletal.json;
          default "";
        }
      '';
      services.nginx.virtualHosts."wikidata-stub" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = wikidataPort;
          }
        ];
        locations = {
          "= /w/rest.php/wikibase/v1/entities/items/Q660045/statements".alias =
            "${wikidata}/statements-Q660045.json";
          "~ ^/w/rest.php/wikibase/v1/entities/items/".return = "400";
          "= /w/api.php".extraConfig = ''
            if ($wikidata_imageinfo = "") { return 404; }
            default_type application/json;
            alias $wikidata_imageinfo;
          '';
        };
        extraConfig = "default_type application/json;";
      };
    };
    testScript = ''
      machine.wait_for_unit("openrailwaymap-import.service", timeout=1800)
      machine.wait_for_unit("openrailwaymap-martin.service")
      machine.wait_for_unit("openrailwaymap-api.service")
      machine.wait_for_unit("nginx.service")
      machine.wait_for_open_port(3001)
      machine.wait_for_open_port(5002)
      machine.wait_for_open_port(8000)
      machine.succeed("hurl --test --variable base_url=http://127.0.0.1:5002/api ${src}/api/test/api.hurl")
      machine.succeed("hurl --test --variable base_url=http://127.0.0.1:8000 ${src}/proxy/test/proxy.hurl")
      print(machine.succeed("su -l ui-test -c ${uiTests}"))
    '';
  };
}

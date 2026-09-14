# The pieces that compose.yaml wires together, as plain Nix packages. The
# NixOS module (module.nix) turns them into systemd services; they can also
# be run by hand (see README.md).
{
  pkgs,
  lib,
  src,
}:
let
  callPackage = lib.callPackageWith (pkgs // { inherit src; });
  node-deps = callPackage ./node-deps.nix { };
  generated = callPackage ./generated.nix { inherit node-deps; };
  proxy = callPackage ./proxy.nix { inherit generated; };
  # With LuaJIT, which osm2pgsql recommends: openrailwaymap.lua assigns to `for`
  # loop variables, which Lua 5.5, nixpkgs' default, forbids, unlike LuaJIT and
  # the Lua 5.4 that upstream tests the style with.
  osm2pgsql = pkgs.osm2pgsql.override { withLuaJIT = true; };
in
{
  inherit node-deps generated osm2pgsql;
  orm-import = callPackage ./import.nix { inherit generated osm2pgsql; };
  orm-martin = callPackage ./martin.nix { };
  orm-api = callPackage ./api.nix { inherit generated; };
  # static site files, and a function rendering the nginx server block
  inherit (proxy) public serverConf;
}

{
  description = "OpenRailwayMap vector tiles: database, import, tile server, API and web site as NixOS services";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # The Berlin extract the container test imports. The test suites assert on
  # recent Berlin data, as upstream's do, so bump the date together with them,
  # with `nix flake update berlin` after editing it. Geofabrik keeps the daily
  # extracts for a few weeks only, so past that the test needs it cached.
  inputs.berlin = {
    url = "file+https://download.geofabrik.de/europe/germany/berlin/berlin-261120.osm.pbf";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      berlin,
    }:
    let
      lib = nixpkgs.lib;
      # The NixOS hosts, and the container test that runs one, are Linux only.
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # The programs, the development shell and the other checks also work on
      # macOS, for developing without a Linux machine.
      systems = linuxSystems ++ [
        "aarch64-darwin"
      ];
      forAll = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      src = self;
      orm = pkgs: pkgs.callPackage ./nix { inherit src; };

      # The NixOS hosts, as their modules (see nixosConfigurations).
      hosts = {
        # Development: `sudo nixos-container create orm --flake .#container-x86_64-linux`
        # on NixOS, or on any Linux with systemd and Nix
        # `sudo nix run .#nixosConfigurations.container-x86_64-linux.config.system.build.nspawn`
        container = [
          self.nixosModules.default
          ./nix/example-host.nix
          (
            { modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/virtualisation/nspawn-container"
                "${modulesPath}/virtualisation/guest-networking-options.nix"
              ];
              boot.isContainer = true;
            }
          )
        ];
        # The production server (deployed by .github/workflows/deploy.yml).
        production = [
          self.nixosModules.default
          ./nix/production.nix
        ];
        # A bootable example host; build an image with e.g.
        #   nix build .#nixosConfigurations.image-x86_64-linux.config.system.build.images.qemu-efi
        # (other variants: raw-efi, amazon, digital-ocean, lxc, proxmox, ...)
        image = [
          self.nixosModules.default
          ./nix/example-host.nix
          ./nix/image.nix
        ];
      };
    in
    {
      # The building blocks: generated files, wrapper scripts, static site.
      # Only those available on the system, so no orm-martin on macOS.
      packages = forAll (
        pkgs:
        lib.filterAttrs (_: p: lib.isDerivation p && lib.meta.availableOn pkgs.stdenv.hostPlatform p) (
          orm pkgs
        )
      );

      # services.openrailwaymap.* for any NixOS host: production is a normal
      # NixOS deployment with this module enabled.
      nixosModules.default = { pkgs, ... }: {
        imports = [
          (import ./nix/module.nix {
            orm = orm pkgs;
            src = self;
          })
        ];
      };

      # Every host is built for each of `linuxSystems` as `<host>-<system>`, e.g.
      # `container-aarch64-linux`.
      nixosConfigurations = lib.concatMapAttrs (
        host: modules:
        lib.listToAttrs (
          map (
            system:
            lib.nameValuePair "${host}-${system}" (
              lib.nixosSystem {
                modules = modules ++ [ { nixpkgs.hostPlatform = system; } ];
              }
            )
          ) linuxSystems
        )
      ) hosts;

      # `nix fmt`: treefmt as nixpkgs itself uses it, with only nixfmt so the
      # upstream JS/Python/YAML stay untouched.
      formatter = forAll (
        pkgs:
        pkgs.treefmt.withConfig {
          runtimeInputs = [ pkgs.gitMinimal ];
          settings.formatter.nixfmt = {
            command = lib.getExe pkgs.nixfmt;
            includes = [ "*.nix" ];
          };
        }
      );

      checks = forAll (
        pkgs:
        let
          checks = import ./nix/checks.nix {
            inherit pkgs src berlin;
            inherit (pkgs) lib;
            orm = orm pkgs;
            nixosModule = self.nixosModules.default;
          };
        in
        # The container test runs a NixOS host, so it needs Linux.
        if pkgs.stdenv.hostPlatform.isLinux then checks else removeAttrs checks [ "container-test" ]
      );

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages =
            # Those of the wrappers the system has: no orm-martin on macOS.
            lib.attrValues (
              lib.intersectAttrs {
                orm-import = null;
                orm-martin = null;
                orm-api = null;
              } self.packages.${pkgs.stdenv.hostPlatform.system}
            )
            ++ [
              pkgs.postgresql_19
              pkgs.osmium-tool
              (orm pkgs).osm2pgsql
              pkgs.hurl
            ];
        };
      });
    };
}

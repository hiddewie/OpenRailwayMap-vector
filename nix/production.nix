# The production host, deployed by .github/workflows/deploy.yml. Adjust the
# hardware and network parts for the actual server (a `hardware-configuration.nix`
# from `nixos-generate-config`, and the disk/bootloader settings below), and the
# public host name.
{ lib, ... }:
{
  imports = [ ./image.nix ];

  services.openrailwaymap = {
    enable = true;
    osmDownloadUrl = "https://download.geofabrik.de/north-america/us/new-york-latest.osm.pbf";
    serverName = "openrailwaymap.app";
    publicHost = "openrailwaymap.app";
    publicProtocol = "https";
    openFirewall = true;
  };

  # TLS: Cloudflare in front, as upstream's deployment, or enable ACME here
  # (see nix/README.md).

  networking.hostName = "openrailwaymap";
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAA... deploy"
  ];
  users.users.root.initialPassword = lib.mkForce null;
  system.stateVersion = "25.11";
}

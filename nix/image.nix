# What a bootable host needs beyond the services: a disk layout for the
# image builders, a login for the console, and the image variants' defaults.
{ lib, modulesPath, ... }:
{
  # image variants (system.build.images.*) supply their own disk and
  # bootloader config; these defaults only matter for a plain evaluation.
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.growPartition = lib.mkDefault true;

  services.openssh.enable = true;
  users.users.root.initialPassword = lib.mkDefault "openrailwaymap";
}

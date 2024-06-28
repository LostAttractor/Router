{ modulesPath, pkgs, lib, ... }:
{
  # Basics
  imports = [ (modulesPath + "/virtualisation/proxmox-image.nix") ];

  # VirtIO
  boot.initrd.availableKernelModules = [ "virtio_scsi" "sd_mod" ];

  # UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  proxmox.qemuConf.bios = "ovmf";

  # Xanmod Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;

  # Enable ZRAM
  zramSwap.enable = true;

  # Allow the user to login as root without password.
  users.users.root.initialHashedPassword = lib.mkOverride 150 "";

  # Some more help text.
  services.getty.helpLine = ''

    Log in as "root" with an empty password.
  '';
}
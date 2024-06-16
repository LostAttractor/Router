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
}
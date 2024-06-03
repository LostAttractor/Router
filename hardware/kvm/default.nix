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

  # Zen Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;

  # Enable ZRAM
  zramSwap.enable = true;
}
_:
{
  imports = [ ./configuration/user.nix ];

  proxmox.qemuConf = {
    bios = "ovmf";
    scsihw = "virtio-scsi-single";
  };

  networking.hostName = "router";
}
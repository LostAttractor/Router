{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

  # Supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

  networking.useHostResolvConf = false;
}
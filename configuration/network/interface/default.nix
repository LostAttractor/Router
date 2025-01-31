{ lib, ... }:
with lib;
{
  # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html
  # TODO: Multiple IPv6 SubnetID(Prefix)
  imports = [
    ./vlan.nix
    ./wan/dhcp
    ./br-lan
    ./security
    ./manage
    ./wireguard
  ];

  config = {
    # Using systemd-networkd
    systemd.network.enable = true;
    networking.useDHCP = false;
  };

  options.network.interface = {
    world = mkOption { type = types.str; };
    private = {
      lan = mkOption { type = types.str; };
      security = mkOption { type = types.str; };
      manage = mkOption { type = types.str; };
      wg = mkOption { type = types.str; };
      tailscale = mkOption { type = types.str; };
    };
  };
}
_:
{
  # Using systemd-networkd
  systemd.network.enable = true;
  networking.useDHCP = false;

  imports = [
    ./vlan.nix
    ./wan/dhcp
    ./br-lan
    ./wireguard
  ];
}
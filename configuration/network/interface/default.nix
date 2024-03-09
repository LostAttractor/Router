_:
{
  # Using systemd-networkd
  systemd.network.enable = true;
  networking.useDHCP = false;

  imports = [
    ./wan/dhcp
    ./br-lan
  ];
}
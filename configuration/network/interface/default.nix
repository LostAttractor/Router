_:
{
  # Using systemd-networkd
  systemd.network.enable = true;
  networking.useDHCP = false;

  imports = [
    ./wan/ppp
    ./br-lan
  ];
}
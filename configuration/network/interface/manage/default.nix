{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.manage}" = {
      name = network.interface.manage;
      networkConfig = {
        Address = [ "10.100.0.1/16" "fd23:3333:3333:100::1/64" ];
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
        IPMasquerade = "ipv4";
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
    };
  };

  network.interface.private.manage = network.interface.manage;
}
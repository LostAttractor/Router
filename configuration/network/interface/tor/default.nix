{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.tor}" = {
      name = network.interface.tor;
      networkConfig = {
        Address = [ "10.1.0.1/16" "fd23:3333:3333:1::1/64" ];
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
    };
  };

  network.interface.private.tor = network.interface.tor;
}
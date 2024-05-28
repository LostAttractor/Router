{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.security}" = {
      name = network.interface.security;
      networkConfig = {
        Address = [ "10.10.0.1/16" "fd23:3333:3333:10::1/64" ];
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
        IPMasquerade = "ipv4";
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
    };
  };

  network.interface.private.security = network.interface.security;
}
{ network, ... }:
{
  systemd.network = {
    netdevs."00-${network.interface.br-lan}".netdevConfig = {
      Kind = "bridge";
      Name = network.interface.br-lan;
    };
    networks."10-${network.interface.lan}" = {
      name = network.interface.lan;
      networkConfig = {
        Bridge = network.interface.br-lan;
        LinkLocalAddressing = "no";
      };
    };
    networks."10-${network.interface.direct}" = {
      name = network.interface.direct;
      networkConfig = {
        Bridge = network.interface.br-lan;
        LinkLocalAddressing = "no";
      };
    };
    networks."10-${network.interface.br-lan}" = {
      name = network.interface.br-lan;
      networkConfig = {
        Address = [ "10.0.0.1/16" "fd23:3333:3333::1/64" ];
        DHCPPrefixDelegation = true;  # 自动选择第一个有 PD 的链路, 并获得子网前缀
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
      dhcpPrefixDelegationConfig.Token = "::1";
    };
  };

  network.interface.private.lan = network.interface.br-lan;
}
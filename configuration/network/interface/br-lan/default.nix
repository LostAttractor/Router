{ network, ... }:
{
  systemd.network = {
    netdevs."10-br-lan".netdevConfig = {
      Kind = "bridge";
      Name = "br-lan";
    };
    networks."20-${network.interface.lan}" = {
      name = network.interface.lan;
      networkConfig = {
        Bridge = "br-lan";
        LinkLocalAddressing = "no";
      };
    };
    networks."20-${network.interface.direct}" = {
      name = network.interface.direct;
      networkConfig = {
        Bridge = "br-lan";
        LinkLocalAddressing = "no";
      };
    };
    networks."30-br-lan" = {
      name ="br-lan";
      networkConfig = {
        Address = "10.0.0.1/16";
        DHCPPrefixDelegation = true;  # 自动选择第一个有 PD 的链路, 并获得子网前缀
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
        IPMasquerade = "ipv4";
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
      dhcpPrefixDelegationConfig.Token = "::1";
    };
  };

  network.nftables.interface.private = "br-lan";
}
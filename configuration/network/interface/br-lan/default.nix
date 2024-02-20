{ network, ... }:
{
  systemd.network = {
    netdevs."20-br-lan".netdevConfig = {
      Kind = "bridge";
      Name = "br-lan";
    };
    networks."30-${network.interface.lan}" = {
      name = network.interface.lan;
      networkConfig = {
        Bridge = "br-lan";
        LinkLocalAddressing = "no";
      };
    };
    networks."40-br-lan" = {
      name ="br-lan";
      networkConfig = {
        Address = "192.168.8.1/24";
        DHCPPrefixDelegation = true;  # 自动选择第一个有 PD 的链路, 并获得子网前缀
        IPv6SendRA = true;
        IPv6AcceptRA = false;  # 接受来自下游的 RA 是不必要的
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
      dhcpPrefixDelegationConfig.Token = "::1";
    };
  };

  networking.nftables.ruleset = ''
    define DEV_PRIVATE = br-lan
    define NET_PRIVATE = 192.168.8.0/24
  '';
}
{ network, ... }:
{
  imports = [ ./pppd.nix ];

  # https://github.com/JQ-Networks/NixOS/blob/a7bf792a4411971d8229eb43a3547097ab06e65b/services/ppp/default.nix#L137
  # https://github.com/RMTT/machines/blob/b58cddca27d81c8bed8fa44e1db4b20dceded40d/nixos/modules/services/pppoe.nix#L49
  systemd.network = {
    networks."10-${network.interface.onu}" = {  # ONU上联接口 / 仅用于管理ONU
      name = network.interface.onu;
      networkConfig.DHCP = "yes";
      dhcpV4Config = {
        UseRoutes = false;
        UseDNS = false;
      };
    };
    networks."10-${network.interface.ppp}" = {
      name = network.interface.ppp;
      networkConfig = {
        DHCP = "ipv6";  # 需要先接收到包含 M Flag 的 RA 才会尝试 DHCP-PD
        KeepConfiguration = "static";  # 防止清除 PPPD 通过 IPCP 获取的 IPV4 地址
      };
      dhcpV6Config = {
        WithoutRA = "solicit";  # 允许上游 RA 没有 M Flag 时启用 DHCP-PD
        UseDNS = false;
        UseAddress = false;  # 无法获得到地址时需要
      };
      routes = [
        { Gateway = "0.0.0.0"; }  # v4默认路由, 因为v4不是networkd管理的，所以仅在reconfigure时工作
        { Gateway = "::"; }  # v6默认路由
      ];
    };
  };

  network.interface.world = network.interface.ppp;
}
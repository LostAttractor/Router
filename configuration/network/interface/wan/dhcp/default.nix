{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.onu}" = {
      name = network.interface.onu;
      networkConfig = {
        DHCP = "yes";
        Address = "192.168.1.2/24";
      };
      dhcpV4Config.UseRoutes = false;
      dhcpV6Config.WithoutRA = "solicit";  # 允许上游 RA 没有 M Flag 时启用 DHCP-PD
      # 将 v4 默认路由的 src 改为设置的静态地址
      routes = [{ routeConfig = { Gateway = "_dhcp4"; PreferredSource = "192.168.1.2"; }; }];
    };
  };

  network.interface.world = network.interface.onu;
  
  # AUTHORITATIVE SERVER
  services.dnsmasq.settings.auth-server = "router.lostattractor.net,${network.interface.onu}";
}
{ network , ... }:
{
  systemd.network = {
    ## Carrier
    networks."01-${network.interface.downstream}" = {
      name = network.interface.downstream;
      networkConfig = {
        LinkLocalAddressing = "no";
        VLAN = with network.interface; [ lan direct security manage ];
      };
      linkConfig = {
        RequiredForOnline = false;
        MTUBytes = "9000";
      };
    };
    ## VLANs
    # lan zone
    netdevs."00-${network.interface.lan}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.lan;
      };
      vlanConfig.Id = 1;
    };
    netdevs."00-${network.interface.direct}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.direct;
      };
      vlanConfig.Id = 2;
    };
    # security zone
    netdevs."00-${network.interface.security}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.security;
      };
      vlanConfig.Id = 10;
    };
    # manage zone
    netdevs."00-${network.interface.manage}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.manage;
      };
      vlanConfig.Id = 100;
    };
  };
}
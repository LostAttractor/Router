{ network , ... }:
{
  # https://unix.stackexchange.com/questions/215580/untagged-interface-in-linux
  systemd.network = {
    # Carrier
    networks."01-${network.interface.downstream}" = {
      name = network.interface.downstream;
      networkConfig = {
        LinkLocalAddressing = "no";
        VLAN = with network.interface; [ lan direct ];
      };
      linkConfig = {
        RequiredForOnline = false;
        MTUBytes = "9000";
      };
    };
    # VLANs
    netdevs."02-${network.interface.lan}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.lan;
      };
      vlanConfig.Id = 1;
    };
    netdevs."02-${network.interface.direct}" = {
      netdevConfig = {
        Kind = "vlan";
        Name = network.interface.direct;
      };
      vlanConfig.Id = 2;
    };
  };
}
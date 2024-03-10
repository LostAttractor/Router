{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.wan}" = {
      name = network.interface.wan;
      networkConfig = {
        DHCP = "yes";
        # DHCPPrefixDelegation = true;  # 让当前接口也像 br-lan 一样通过 PD 获得一个地址
      };
      dhcpV6Config.WithoutRA = "solicit";  # 允许上游 RA 没有 M Flag 时启用 DHCP-PD
      dhcpPrefixDelegationConfig = {
        UplinkInterface = ":self";
        SubnetId = 0;
        Announce = false;
      };
    };
  };

  networking.nftables.ruleset = ''
    define DEV_WORLD = ${network.interface.wan}

    table inet nat {
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        # Masquerade for layer 3 forwarding
        iifname $DEV_PRIVATE oifname $DEV_WORLD masquerade
      }
    }
  '';
  
  # AUTHORITATIVE SERVER
  services.dnsmasq.settings.auth-server = "router.lostattractor.net,${network.interface.wan}";
}
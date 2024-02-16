_:
{
  # Configure firewall directly using nftables
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain inbound_world {
          # Accepting ping (icmp-echo-request) for diagnostic purposes.
          # However, it also lets probes discover this host is alive.
          icmp type echo-request limit rate 5/second accept
          icmpv6 type echo-request limit rate 5/second accept

          # Allow all IPv6 inbound
          ip6 version 6 accept
        }

        chain input {
          type filter hook input priority filter; policy drop;

          # Allow traffic from established and related packets, drop invalid
          ct state vmap { established : accept, related : accept, invalid : drop }

          # Allow DHCPv6 Packet from $DEV_WORLD
          iifname $DEV_WORLD udp dport dhcpv6-client udp sport dhcpv6-server accept

          # loopback: accept
          # $DEV_PRIVATE: accept
          # $DEV_WORLD: jump to -> inbound_world
          iifname vmap { lo : accept, $DEV_PRIVATE : accept, $DEV_WORLD : jump inbound_world }
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          # Clamp MSS to pMTU
          # Needed for interface such as ppp or vpns
          # Here is enabled for all interfaces as this does not cause any side effects
          # Also this is helpful when using jumbo frames
          tcp flags syn tcp option maxseg size set rt mtu

          # Allow traffic from established and related packets, drop invalid
          ct state vmap { established : accept, related : accept, invalid : drop }

          # $DEV_PRIVATE: accept
          # $DEV_WORLD: jump to -> inbound_world
          iifname vmap { $DEV_PRIVATE : accept, $DEV_WORLD : jump inbound_world }
        }
      }
    '';
  };
}
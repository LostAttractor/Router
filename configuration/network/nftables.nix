{ network, ... }:
{
  # Configure firewall directly using nftables
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;

    # https://discourse.nixos.org/t/nftables-could-not-process-rule-no-such-file-or-directory/33031
    checkRuleset = false;

    ruleset = ''
      table inet filter {
        # Enable flow offloading for better throughput
        flowtable f {
          # Either physical interface or bridge/layer two encapsulation interface can be used.
          # Nftables is started before networkd, so the bridge and layer 2 encapsulated interfaces do not yet exist when nftables is started, 
          # so it is necessary to bind to the physical interface.
          # Also, a physical interface may have multiple Layer 2 encapsulations or bridges above it.
          # https://docs.kernel.org/networking/nf_flowtable.html#layer-2-encapsulation
          # https://docs.kernel.org/networking/nf_flowtable.html#bridge-and-ip-forwarding
          hook ingress priority 0; devices = { ${network.interface.lan}, ${network.interface.wan} };
          # Hardware offload only works on physical hardware
          # flags offload;
        }

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

          # Enable flow offloading for better throughput
          ip protocol { tcp, udp } flow add @f

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
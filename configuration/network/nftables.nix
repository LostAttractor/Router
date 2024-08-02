{ network, config, ... }:

with config.network.interface;
{
  # Configure firewall directly using nftables
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;

    # https://discourse.nixos.org/t/nftables-could-not-process-rule-no-such-file-or-directory/33031
    checkRuleset = false;

    tables = {
      filter = {
        family = "inet";
        content = ''
          flowtable f {
            # Either physical interface or bridge/layer two encapsulation interface can be used.
            # Nftables is started before networkd, so the bridge and layer 2 encapsulated interfaces do not yet exist when nftables is started, 
            # so it is necessary to bind to the physical interface.
            # Also, a physical interface may have multiple Layer 2 encapsulations or bridges above it.
            # https://docs.kernel.org/networking/nf_flowtable.html#layer-2-encapsulation
            # https://docs.kernel.org/networking/nf_flowtable.html#bridge-and-ip-forwarding

            # TODO: Software-defined interfaces such as wireguard may cause problems due to startup sequence
            hook ingress priority 0; devices = { ${network.interface.downstream}, ${network.interface.upstream} };
            # Hardware offload only works on physical hardware
            # flags offload;
          }

          chain inbound {
            type filter hook input priority filter; policy drop;

            # Accepting traffic from established and related packets, drop invalid
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Accepting ICMP
            ip protocol icmp limit rate 5/second accept
            ip6 nexthdr icmpv6 limit rate 5/second accept

            # Accepting DHCPv6 Message from ${world}
            iifname ${world} udp dport dhcpv6-client udp sport dhcpv6-server accept

            # Accepting DHCP Message from all local networks
            iifname != ${world} udp dport 67 accept

            # Accepting SSH/DNS/Wireguard from all networks
            ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 51820 : accept }
            ip6 nexthdr . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 51820 : accept }

            # Accepting traffic from loopback/lan/vpns
            iifname vmap { lo : accept, ${private.lan} : accept, ${private.wg} : accept, ${private.tailscale} : accept }

            # The rest is dropped by the above policy
          }

          chain weak_security_zone {
            # Accepting ping (icmp-echo-request) for diagnostic purposes.
            # However, it also lets probes discover this host is alive.
            icmp type echo-request limit rate 5/second accept
            icmpv6 type echo-request limit rate 5/second accept

            # Accepting all IPv6
            ip6 version 6 accept
          }

          chain strong_security_zone {
            # WIP
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            # Enable flow offloading for better throughput
            ip protocol { tcp, udp } flow add @f
            ip6 nexthdr { tcp, udp } flow add @f

            # Clamp MSS to pMTU
            # Needed for interface such as ppp or vpns
            # Here is enabled for all interfaces as this does not cause any side effects
            # Also this is helpful when using jumbo frames
            tcp flags syn tcp option maxseg size set rt mtu

            # Accepting traffic from established and related packets, drop invalid
            ct state vmap { established : accept, related : accept, invalid : drop }

            # any      ->  world:    accept
            # vpns     <-> lan:      accept
            # lan/vpns ->  manage:   accept
            # world    ->  lan/vpns: jump weak_security_zone
            # any      ->  security: jump strong_security_zone

            oifname ${world} accept
            meta iifname . meta oifname { ${private.lan} . ${private.wg}, ${private.lan} . ${private.tailscale}, ${private.wg} . ${private.lan}, ${private.tailscale} . ${private.lan} } accept
            oifname ${private.manage} iifname vmap { ${private.lan} : accept, ${private.wg} : accept, ${private.tailscale} : accept }
            iifname ${world} oifname vmap { ${private.lan} : jump weak_security_zone, ${private.wg} : jump weak_security_zone, ${private.tailscale} : jump weak_security_zone }
            oifname ${private.security} jump strong_security_zone

            # The rest is dropped by the above policy
          }
        '';
      };
      nat = {
        family = "inet";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;

            # full-cone nat local address
            ip saddr 10.0.0.0/8 ip daddr != 10.0.0.0/8 fullcone

            # full-cone nat ula addresses
            ip6 saddr fc00::/7 ip6 daddr != fc00::/7 fullcone
          }

          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            fullcone
          }
        '';
      };
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      nftables = prev.nftables.overrideAttrs (oldAttrs: with prev; {
        patches = oldAttrs.patches or [ ] ++ [
          (fetchurl {
            url = "https://raw.githubusercontent.com/debiansid/nftables-fullcone/vyos/1.1.0-1/0001-nftables-add-fullcone-expression-support.patch";
            hash = "sha256-CK1IDb/CrYMSXm52wj6k7CjJ1fZvupzxvDaRCBbOmVU=";
          })
        ];
      });
      libnftnl = prev.libnftnl.overrideAttrs (oldAttrs: with prev; {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ autoreconfHook ];
        patches = oldAttrs.patches or [ ] ++ [
          (fetchurl {
            url = "https://raw.githubusercontent.com/debiansid/libnftnl-fullcone/vyos/1.2.7-1/0001-add-fullcone-expression-support.patch";
            hash = "sha256-IQVaF3pg+c3omH82gDGa85VgqqYDwHMccDFCMUu1+rU=";
          })
        ];
      });
    })
  ];
}
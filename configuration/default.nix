{ pkgs, inputs, ... }:
{
  imports = [
    ./network/interface
    ./network/dnsmasq.nix
    ./network/mosdns.nix
    ./network/nftables.nix
    ./network/hosts.nix
    ./features/network/ddns.nix
    ./features/network/miniupnpd.nix
    ./features/network/tailscale.nix
    ./features/network/dae.nix
    ./features/network/tor.nix
    (inputs.homelab + "/features/basic.nix")
    (inputs.homelab + "/features/network/avahi")
    (inputs.homelab + "/features/nix")
    (inputs.homelab + "/features/fish.nix")
    (inputs.homelab + "/features/develop.nix")
    (import (inputs.homelab + "/features/telemetry/mdns.nix") ({ inherit config; promtail_password_file = config.sops.secrets.promtail.path; }))
    ./features/telemetry.nix
    ./user.nix
  ];


  # Load before sysctl (using systemd-modules-load.service)
  boot.kernelModules = [ "nf_conntrack" ];

  # /proc/sys/ to should be writeble
  boot.kernel.sysctl = {
    ### Conntrack
    "net.netfilter.nf_conntrack_acct" = true;
    "net.netfilter.nf_conntrack_timestamp" = true;
    "net.netfilter.nf_conntrack_buckets" = 262144;
    "net.netfilter.nf_conntrack_max" = 262144;
    # Timeout
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 21600;  # Default: 432000
    "net.netfilter.nf_conntrack_udp_timeout" = 60;
    "net.netfilter.nf_conntrack_udp_timeout_stream" = 180;
    ## Layer 3 forwarding
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    ## TCP optimization
    # TCP Fast Open is a TCP extension that reduces network latency by packing
    # data in the sender’s initial TCP SYN. Setting 3 = enable TCP Fast Open for
    # both incoming and outgoing connections:
    "net.ipv4.tcp_fastopen" = 3;
    ## TCP congestion control
    "net.ipv4.tcp_congestion_control" = "bbr";
    ## Queueing discipline
    ## https://www.bufferbloat.net/projects/codel/wiki/
    ## https://www.bufferbloat.net/projects/codel/wiki/Cake/
    "net.core.default_qdisc" = "cake";
    ## UDP Buffersize (https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes)
    ## https://docs.redhat.com/en/documentation/red_hat_data_grid/7.2/html/performance_tuning_guide/networking_configuration#adjusting_send_receive_window_settings
    "net.core.wmem_max" = 655360;
    "net.core.rmem_max" = 26214400;
    "net.ipv4.tcp_wmem" = "4096 16384 655360";
    "net.ipv4.tcp_rmem" = "4096 87380 26214400";
  };

  # https://nixos.wiki/wiki/Networkd-dispatcher
  services.networkd-dispatcher = {
    enable = true;
    rules = {
      "50-offload" = {
        onState = [ "routable" "carrier" ];
        # https://www.kernel.org/doc/html/latest/networking/segmentation-offloads.html
        # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
        # https://tailscale.com/blog/more-throughput
        # https://lore.kernel.org/netdev/90c19324a093536f1e0e2e3de3a36df4207a28d3.camel@redhat.com
        # https://lore.kernel.org/netdev/20220203015140.3022854-15-eric.dumazet@gmail.com
        script = ''
          #!${pkgs.runtimeShell}
          ${pkgs.ethtool}/bin/ethtool -K $IFACE tx-udp-segmentation on rx-udp-gro-forwarding on rx-gro-list off
          ${pkgs.iproute2}/bin/ip link set dev $IFACE gso_max_size 524280 gro_max_size 524280
          ${pkgs.iproute2}/bin/ip link set dev $IFACE gso_ipv4_max_size 524280 gro_ipv4_max_size 524280
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    neofetch hyfetch                 # to see system infomation
    ppp                              # for some manual debugging of pppd
    conntrack-tools                  # view network connection states
    wireguard-tools                  # view wireguard status
    iperf3 speedtest-go cfspeedtest  # speedtest tools
    tcping-go gping mtr trippy       # latency/tracing tools
    bridge-utils                     # brctl
    cloudflared                      # cloudflare zero trust
    stuntman                         # stun
  ];

  proxmox.qemuConf.net0 = "";

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets.promtail.owner = "promtail";

  system.stateVersion = "24.05";
}

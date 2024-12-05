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
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 21600;
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
    "net.core.rmem_max" = 7500000;
    "net.core.wmem_max" = 7500000;
  };

  environment.systemPackages = with pkgs; [
    htop btop                        # to see the system load
    neofetch hyfetch                 # to see system infomation
    ppp                              # for some manual debugging of pppd
    ethtool                          # manage NIC settings (offload, NIC feeatures, ...)
    tcpdump                          # view network traffic
    conntrack-tools                  # view network connection states
    wireguard-tools                  # view wireguard status
    dnsutils                         # dns tools
    iperf3 speedtest-go cfspeedtest  # speedtest tools
    tcping-go gping mtr trippy       # latency/tracing tools
    inetutils                        # telnet
    bridge-utils                     # brctl
    nmap
    strace
  ];

  proxmox.qemuConf.net0 = "";

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets.promtail.owner = "promtail";

  system.stateVersion = "24.05";
}

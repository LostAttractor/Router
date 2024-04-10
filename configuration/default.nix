{ pkgs, ... }:
{
  imports = [
    ./network/interface
    ./network/dnsmasq.nix
    ./network/nftables.nix
    ./features/ddns.nix
    ./features/miniupnpd.nix
    ./features/dae.nix
    ./features/nix.nix
    ./features/fish.nix
    ./features/prometheus.nix
    ./user.nix
  ];

  # /proc/sys/ to should be writeble
  boot.kernel.sysctl = {
    ## Layer 3 forwarding
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    ## TCP optimization
    # TCP Fast Open is a TCP extension that reduces network latency by packing
    # data in the sender’s initial TCP SYN. Setting 3 = enable TCP Fast Open for
    # both incoming and outgoing connections:
    "net.ipv4.tcp_fastopen" = 3;
    # Bufferbloat mitigations + slight improvement in throughput & latency
    "net.ipv4.tcp_congestion_control" = "bbr";
    ## Queueing discipline
    "net.core.default_qdisc" = "cake";
  };

  boot.kernelModules = [ "tcp_bbr" ];

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

  sops.defaultSopsFile = ../secrets.yaml;

  system.stateVersion = "24.05";
}

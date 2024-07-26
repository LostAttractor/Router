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
    (inputs.homelab + "/features/telemetry/mdns.nix")
    ./features/telemetry.nix
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
    ## Queueing discipline
    "net.core.default_qdisc" = "cake";
    ## UDP Buffersize (https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes)
    "net.core.rmem_max" = 7500000;
    "net.core.wmem_max" = 7500000;
  };


  # https://nixos.wiki/wiki/Networkd-dispatcher
  services.networkd-dispatcher = {
    enable = true;
    rules = {
      "50-tailscale" = {
        onState = [ "routable" ];
        # https://www.kernel.org/doc/html/latest/networking/segmentation-offloads.html
        script = ''
          #!${pkgs.runtimeShell}
          ${pkgs.ethtool}/bin/ethtool -K $IFACE rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
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

  system.stateVersion = "24.05";
}

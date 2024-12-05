{ config, pkgs, ... }:
{
  systemd.network = {
    networks."10-${config.network.interface.world}" = {
      cakeConfig = {
        Bandwidth = "105M";
        RTTSec = "50ms";
      };
    };
    netdevs."00-ifb4${config.network.interface.world}".netdevConfig = {
      Kind = "ifb";
      Name = "ifb4${config.network.interface.world}";
    };
    networks."10-ifb4${config.network.interface.world}" = {
      name = "ifb4${config.network.interface.world}";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = false;
      cakeConfig = {
        Bandwidth = "960M";
        # OverheadBytes = 50;  # 35 是典型的PON网络开销, 38 是典型的以太网开销, 当前实践可能不应低于 50
        RTTSec = "50ms";
      };
    };
  };

  # clsact 和 ingress 互相是排他性的 (Exclusivity)
  # clsact 是 ingress (和egress)? 加载 bpf 程序的前提
  # 它们都会有一个句柄, 对于 clsact, 它不会被使用, 因此可以省略

  services.networkd-dispatcher.rules."10-tc" = {
    onState = [ "routable" ]; # or configured
    script = ''
      #!${pkgs.runtimeShell}
      if [[ $IFACE == "${config.network.interface.world}" ]] && ! ${pkgs.iproute2}/bin/tc filter show dev "${config.network.interface.world}" ingress | grep -q "\[tc/redirect\]"; then
        # Load bpf program if not loaded yet
        if ! tc qdisc show dev ${config.network.interface.world} | grep -q "clsact"; then
          ${pkgs.iproute2}/bin/tc qdisc add dev "${config.network.interface.world}" clsact
        fi
        ${pkgs.iproute2}/bin/tc filter add dev "${config.network.interface.world}" ingress bpf direct-action obj ${pkgs.callPackage ./bpf {}}/redirect.o sec tc/redirect
        # Update if_index
        ifindex=$(${pkgs.iproute2}/bin/ip -json link | ${pkgs.jq}/bin/jq '.[] | select(.ifname == "ifb4${config.network.interface.world}") | .ifindex')
        ${pkgs.bpftools}/bin/bpftool map update pinned /sys/fs/bpf/tc/globals/ifindex_map key 0x0 0x0 0x0 0x0 value 0x$ifindex 0x0 0x0 0x0
      fi
    '';
  };

  # services.networkd-dispatcher.rules."10-tc" = {
  #   onState = [ "routable" ];
  #   script = ''
  #     #!${pkgs.runtimeShell}
  #     if [[ $IFACE == "${network.interface.upstream}" ]]; then
  #       # ${pkgs.iproute2}/bin/tc qdisc del dev ${network.interface.upstream} ingress
  #       ${pkgs.iproute2}/bin/tc qdisc add dev ${network.interface.upstream} handle ffff: ingress
  #       ${pkgs.iproute2}/bin/tc filter add dev ${network.interface.upstream} parent ffff: matchall action mirred egress redirect dev ifb4${config.network.interface.world}
  #     fi
  #   '';
  # };
}
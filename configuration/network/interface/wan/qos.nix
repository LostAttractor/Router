{ config, pkgs, ... }:
{
  # 流量必须不拥塞在ISP处, 不然一切都没有意义
  # 如果ISP处不存在瓶颈, 则我可以优先丢弃会导致队列膨胀的包, 并接收不导致队列膨胀的包, 而 ISP 限速时使用的丢弃方法一般是rate limit
  # 实际上我的接收没有瓶颈, 但丢弃保证了上游ISP的限速不会触发, 因此不导致队列膨胀的包我可以正常收到, 导致队列膨胀的包则因为丢弃降速以保证上游 ISP 的限速不触发
  # 因此这里使用 CAKE 并锁定速率
  # 但事实上瓶颈可能在光猫的千兆链路? 那其实道理也一样, 不过应该设法解决这个瓶颈
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
        Bandwidth = "1000M";
        OverheadBytes = 50;  # 35 是典型的PON网络开销, 38 是典型的以太网开销, 当前实践可能不应低于 50
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
      if [[ $IFACE == "${config.network.interface.world}" ]] && ! ${pkgs.iproute2}/bin/tc filter show dev "${config.network.interface.world}" ingress | grep -q "mirred"; then
        # Add parent qdisc if not loaded yet
        if ! tc qdisc show dev ${config.network.interface.world} | grep -q "clsact"; then
          ${pkgs.iproute2}/bin/tc qdisc add dev "${config.network.interface.world}" clsact
        fi
        ${pkgs.iproute2}/bin/tc filter add dev ${config.network.interface.world} ingress matchall action mirred egress redirect dev ifb4${config.network.interface.world}
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
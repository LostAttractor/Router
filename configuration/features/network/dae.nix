{ config, network, ... }:
{
  services.dae = {
    enable = true;
    configFile = config.sops.templates."config.dae".path;
    assets = with pkgs; lib.mkForce [ v2dat-geoip v2dat-geosite ];
  };

  sops.templates."config.dae".content = ''
    global {
      # Bind to LAN and/or WAN as you want. Replace the interface name to your own.
      lan_interface: ${network.interface.lan}, ${network.interface.manage}, ${network.interface.wg}, ${network.interface.tailscale}
      wan_interface: auto # Use "auto" to auto detect WAN interface.

      log_level: info
      allow_insecure: false
      auto_config_kernel_parameter: true

      check_interval: 360s # or 180?

      # domain:   进行 SNI 嗅探, 会验证 SNI 是否可信, 通过要求客户端每次进行连接时都产生 DNS 查询, 将 SNI/目标IP 与 DNS/查询结果 进行匹配
      #           如果一致, 则覆盖连接目标为 SNI 目标, 这要求 DAE 监听所有客户端的 DNS 请求并进行缓存, 以保证客户端每次发起连接时都重新进行 DNS 查询
      #           DAE 会篡改 TTL 为 0, 因此只要 DNS 查询链路尊重上游 TTL, 即便下游有缓存也不会导致问题, 而缓存工作由 DAE 完成
      #           但显然这样的行为会使得 TTL 缓存完全失效, 增加网络负担和延迟
      #           但这不会改变路由
      # domain+:  忽略 SNI 验证, 这使得 DNS 查询可以完全不经由 DAE 处理, 不过这可能导致提供了错误的SNI的情况下无法工作, 如 Tor
      # domain++: 忽略 SNI 验证的同时, 以嗅探到的域名重新进行路由, 带来更好的准确度, 同时也意味着整个过程中，如果域名分流正确工作，可以抵御 DNS 污染
      #           但也带来了更大的性能开销
      dial_mode: domain++  # SNI错误?
    }

    subscription {
      nexitally: '${config.sops.placeholder."dae/subscription/nexitally"}'
      imm: '${config.sops.placeholder."dae/subscription/imm"}'
      cnix: '${config.sops.placeholder."dae/subscription/cnix"}'
    }

    group {
      proxy {
        filter: subtag(nexitally) && name(keyword: 'Japan') && !name(keyword: 'Premium')
        filter: subtag(imm) && name(keyword: 'JPN')
        filter: subtag(cnix) && name(keyword: 'PVCC') [add_latency: +1000ms]
        policy: min_avg10
      }
      proxy_jp {
        filter: subtag(nexitally) && name(keyword: 'Japan') && !name(keyword: 'Premium')
        filter: subtag(imm) && name(keyword: 'JPN')
        filter: subtag(cnix) && name(keyword: '日本') [add_latency: +1000ms]
        policy: min_avg10
      }
      proxy_hk {
        filter: subtag(nexitally) && name(keyword: 'Hong Kong') && !name(keyword: 'Premium')
        filter: subtag(imm) && name(keyword: 'HKG')
        filter: subtag(cnix) && name(keyword: '香港') [add_latency: +1000ms]
        policy: min_avg10
      }
      proxy_tw {
        filter: subtag(nexitally) && name(keyword: 'Taiwan') && !name(keyword: 'Premium')
        filter: subtag(imm) && name(keyword: 'TWN')
        filter: subtag(cnix) && name(keyword: '台湾') [add_latency: +1000ms]
        policy: min_avg10
      }
      proxy_sg {
        filter: subtag(nexitally) && name(keyword: 'Singapore') && !name(keyword: 'Premium')
        filter: subtag(imm) && name(keyword: 'SGP')
        filter: subtag(cnix) && name(keyword: '新加坡') [add_latency: +1000ms]
        policy: min_avg10
      }
    }

    # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/routing.md for full examples.
    routing {
      ## DO NOT hijack DNS (for ip/domain++ mode)
      # Client -> DNSMASQ -> MOSDNS -(DOH)-> Upstream
      dport(53) -> must_rules
      ## Or hijack and sniff verify (for domain mode, not working for router itself)
      ## Client -(sniff verify)-> DNSMASQ -> MOSDNS -(no verify) -> Upstream
      ## Client -(no verify)-> Upstream
      # dport(53) && !dip(geoip:private) -> must_rules

      ## Bypass Private IPs
      dip(geoip:private) -> direct

      ## Application-based routing
      # Bypass DSCP 0x4 (e.g. Bittorrent)
      dscp(0x4) -> direct

      ## Region-based routing
      # Bypass CN
      dip(geoip:cn) -> direct
      domain(geosite:cn) -> direct

      # Proxy
      dip(geoip:jp) -> proxy_jp
      dip(geoip:hk) -> proxy_hk
      dip(geoip:tw) -> proxy_tw
      dip(geoip:sg) -> proxy_sg
      fallback: proxy
    }
  '';

  sops.secrets."dae/subscription/nexitally" = {};
  sops.secrets."dae/subscription/imm" = {};
  sops.secrets."dae/subscription/cnix" = {};
}
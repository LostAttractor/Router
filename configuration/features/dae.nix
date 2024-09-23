{ config, ... }:
{
  services.dae = {
    enable = true;
    configFile = config.sops.templates."config.dae".path;
  };

  sops.templates."config.dae".content = ''
    global {
      # Bind to LAN and/or WAN as you want. Replace the interface name to your own.
      lan_interface: br-lan, wg0
      wan_interface: auto # Use "auto" to auto detect WAN interface.

      log_level: info
      allow_insecure: false
      auto_config_kernel_parameter: true

      # domain:   进行 SNI 嗅探, 会验证 SNI 是否可信, 通过发起一次DNS请求以判断SNI域名的解析结果是否和连接目标一致, 如果一致, 则覆盖连接目标为SNI域名
      #           这要求 DAE 监听所有客户端的 DNS 请求并进行缓存, 并要求客户端每次发起连接时都重新进行 DNS 查询, 以保证连接目标和 DAE 的缓存一致
      #           DAE 会篡改 TTL 为 0, 因此只要 DNS 查询链路尊重上游 TTL, 即便下游有缓存也不会导致问题, 而缓存工作由 DAE 完成
      #           但显然这样的行为会使得 TTL 缓存完全失效, 增加网络负担和延迟
      # domain+:  忽略 SNI 验证, 这使得 DNS 查询可以完全不经由 DAE 处理, 不过这可能导致提供了错误的SNI的情况下无法工作, 如APNS
      # domain++: 忽略 SNI 验证的同时, 并以嗅探到的域名重新进行路由, 带来更好的准确度, 同时也意味着整个过程中，如果域名分流正确工作，可以抵御 DNS 污染
      #           但也带来了更大的性能开销
      # dial_mode: domain++  # SNI错误?
    }

    subscription {
      nexitally: '${config.sops.placeholder."dae/subscription/nexitally"}'
    }

    # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/dns.md for full examples.
    dns {
      upstream {
        googledns: 'tcp+udp://dns.google.com:53'
      }
      routing {
        request {
          qname(geosite:category-ads-all) -> reject
          qname(geosite:cn) -> asis
          fallback: googledns
        }
      }
    }

    group {
      proxy {
        filter: name(keyword: 'Japan') && !name(keyword: 'Premium')
        policy: min_avg10
      }
    }

    # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/routing.md for full examples.
    routing {
      ### UDP Bypass
      # Because there is currently no UDP conntrack,
      # you need to allow the UDP Server's reply traffic to be directly connected
      # https://github.com/daeuniverse/dae/issues/475
      # For example: dnsmasq
      sport(53) && pname(dnsmasq) -> direct
      
      # Hijack only DNS queries from dnsmasq and systemd-resolved
      dport(53) && pname(dnsmasq) -> direct
      dport(53) && pname(systemd-resolved) -> direct
      dport(53) -> must_rules
      # TODO: Should be equivalent but doesn't work now
      # https://github.com/daeuniverse/dae/issues/474
      # dport(53) && !pname(systemd-resolved) && !pname(dnsmasq) -> must_rules

      # Bypass Private IP
      dip(geoip:private) -> direct

      # Bypass CN
      dip(geoip:cn) -> direct
      domain(geosite:cn) -> direct

      fallback: proxy
    }
  '';

  sops.secrets."dae/subscription/nexitally" = {};
}
{ inputs, ... }:
# https://openwrt.org/docs/guide-user/base-system/dhcp
# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
let 
  domain = "home.lostattractor.net";
in {
  services.dnsmasq = {
    enable = true;
    # Get upstream from systemd-resolved 
    # And using dnsmasq to resolve local queries
    resolveLocalQueries = true;
    settings = {
      # Local domain
      domain = domain;
      local = "/${domain}/";  # Not forwarding local domain to upstream
      expand-hosts = true;
      # Interface bind
      interface = "br-lan";
      bind-dynamic = true;
      # Bind domain to interface's IPs
      interface-name = "router.${domain},br-lan";
      # Cache
      cache-size = 8192;
      no-negcache = true;
      # Ensure requests for local hostnames (without dots or domain parts) aren't forwarded to upstream DNS servers
      domain-needed = true;
      # Pervent reverse DNS lookups for local hosts
      bogus-priv = true;
      # Allows returning different results to different interfaces
      # For an authoritative server, when encountering a CNAME, only the corresponding domain name needs to be returned
      # For a recursive resolver, when encountering a CNAME, it needs to return both the domain name and the result (or only the result?)
      # Since DNSMASQ both acts as an authoritative server/recursive resolver, It needs to be allowed to return different results for different interfaces.
      localise-queries = true;  # 关闭此选项似乎会导致包含在 auth-zone 的 CNAME 在非 auth-server 绑定的接口也不返回实际 IP, 尚不清楚成因
      # DHCP
      dhcp-authoritative = true;
      dhcp-broadcast = "tag:needs-broadcast";
      dhcp-ignore-names = "tag:dhcp_bogus_hostname";
      dhcp-range = [
        "set:br-lan,10.0.1.0,10.0.254.255"  # Reserve 10.0.0.0/24 & 10.0.255.0/24
        "set:br-lan,::ff,::ffff,constructor:br-lan,ra-names,1h"
        # TODO: IPv6需要通过让接口获得不一样的前缀来区分地址, 这里只实现保留大部分后缀地址，但不区分前缀
        # 未来的管理面VLAN和生成环境VLAN可能或需要不同的前缀用于区分
      ];
      read-ethers = true;
      # CNAME
      cname = [
        "binarycache.${domain},hydra.${domain}"
        "qbittorrent.${domain},nextcloud.${domain},emby.${domain},nixnas.${domain}"
        "portainer.${domain},nginx.${domain},alist.${domain},memos.${domain},pdf.${domain},container.${domain}"
        "uptime.${domain},prometheus.${domain},grafana.${domain},metrics.${domain}"
      ];
      # AUTHORITATIVE ZONE
      auth-zone = "${domain}";
      # ADBlock
      conf-file = "${inputs.anti-ad}/adblock-for-dnsmasq.conf";
    };
  };
}
_:
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
        "set:br-lan,192.168.8.100,192.168.8.254"
        "set:br-lan,::ff,::ffff,constructor:br-lan,ra-names,1h"
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
    };
  };
}
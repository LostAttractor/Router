{ inputs, config, network, ... }:
# https://openwrt.org/docs/guide-user/base-system/dhcp
# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
let
  domain = network.domain;
in {
  services.resolved.enable = false;

  services.dnsmasq = {
    enable = true;
    settings = with config.network.interface; {
      # Upstream (mosdns)
      server = [ "127.0.0.53" ];
      no-resolv = true;
      # Local domain
      domain = domain;
      local = "/${domain}/";  # Not forwarding local domain to upstream
      expand-hosts = true;
      # Interface bind
      interface = [ private.lan private.security private.manage ];
      bind-dynamic = true;
      # Bind domain to interface's IPs
      interface-name = "router.${domain},${private.lan}";
      # Cache
      cache-size = 8192;
      # This will cause a re-request to the upstream every time you resolve the ipv4 single-stack domain name because the ipv6 address is not obtained and cached.
      # no-negcache = true;
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
        # lan
        "set:${private.lan},10.0.1.0,10.0.254.255"  # Reserve 10.0.0.0/24 & 10.0.255.0/24
        "set:${private.lan},::fff,::ffff,constructor:${private.lan},ra-names"
        # security
        "set:${private.security},10.10.1.0,10.10.254.255"  # Reserve 10.10.0.0/24 & 10.10.255.0/24
        "set:${private.security},::fff,::ffff,constructor:${private.security},ra-names"
        # manage
        "set:${private.manage},10.100.1.0,10.100.254.255"  # Reserve 10.100.0.0/24 & 10.100.255.0/24
        "set:${private.manage},::fff,::ffff,constructor:${private.manage},ra-names"
      ];
      # Binding
      dhcp-host = [
        "30:37:b3:8b:58:60,LeaderAP"
        "78:60:5b:97:dc:70,TL-ST5008F"
        "68:dd:b7:0c:ec:3c,TL-SE2109PB"
      ];
      read-ethers = true;
      # CNAME
      cname = [
        "binarycache.${domain},hydra.${domain}"
        "qbittorrent.${domain},nextcloud.${domain},emby.${domain},nixnas.${domain}"
        "portainer.${domain},nginx.${domain},alist.${domain},memos.${domain},pdf.${domain},container.${domain}"
        "uptime.${domain},prometheus.${domain},grafana.${domain},metrics.${domain}"
      ];
      # AUTHORITATIVE
      auth-zone = "${domain}";
      auth-server = "${domain},${world}";
      # ADBlock
      conf-file = "${inputs.oisd}/dnsmasq2_big.txt";
    };
  };
}
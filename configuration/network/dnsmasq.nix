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
      interface-name = [ "${domain},${private.lan}" "router.${domain},${private.lan}" ];
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
        "set:${private.lan},10.0.1.0,10.0.254.255,24h"  # Reserve 10.0.0.0/24 & 10.0.255.0/24
        "set:${private.lan},::fff,::ffff,constructor:${private.lan},ra-names"
        # security
        "set:${private.security},10.10.1.0,10.10.254.255,24h"  # Reserve 10.10.0.0/24 & 10.10.255.0/24
        "set:${private.security},::fff,::ffff,constructor:${private.security},ra-names"
        # manage
        "set:${private.manage},10.100.1.0,10.100.254.255,24h"  # Reserve 10.100.0.0/24 & 10.100.255.0/24
        "set:${private.manage},::fff,::ffff,constructor:${private.manage},ra-names"
      ];
      # Binding
      dhcp-host = [
        "54:f6:e2:e6:6e:80,LeaderAP"
        "78:60:5b:97:dc:70,TL-ST5008F"
        "68:dd:b7:0c:ec:3c,TL-SE2109PB"
      ];
      read-ethers = true;
      # CNAME
      cname = [
        "binarycache.${domain},hydra.${domain}"
        "qbittorrent.${domain},emby.${domain},jellyfin.${domain},immich.${domain},ipfs.${domain},api.ipfs.${domain},syncthing.${domain},nas.${domain}"
        # "qbittorrent.legceynas.${domain},emby.legceynas.${domain},immich.legceynas.${domain},ipfs.legceynas.${domain},api.ipfs.legceynas.${domain},syncthing.legceynas.${domain},nixnas.${domain}"
        "authentik.${domain},vaultwarden.${domain},argocd.${domain},hubble.${domain},portainer.${domain},memos.${domain},pdf.${domain},longhorn.${domain},grafana.${domain},uptime.${domain},prometheus.${domain},loki.${domain},node0-rke.${domain}"
        "zabbix.${domain},metrics.${domain}"
        "rancher.${domain},harvester.${domain}"
      ];
      # AUTHORITATIVE
      # 作为权威的范围, 这会使得对应内容变得权威 (+authority), 并且提供 AUTHORITY SECTION (NS记录, 或许也可以是 SOA 记录)
      auth-zone = "${domain},${private.lan}/6,exclude:fc00::/7";
      # 需要注意的是这不能适用于需要作为递归 DNS 服务器的接口, 因为会导致 CNAME 不可用, 此外该接口不需要包括在 interface 中 (否则会进行覆盖)
      auth-server = "${domain},${world}";
      # ADBlock
      conf-file = "${inputs.oisd}/dnsmasq2_big.txt";
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
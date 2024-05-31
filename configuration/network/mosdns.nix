{ inputs, ... }:
{
  services.mosdns ={
    enable = true;
    config = {
      log.level = "info";
      api.http = ":9154";

      plugins = [
        # Domain/IP set
        {
          tag = "ads"; type = "domain_set";
          args.files = [ "${inputs.oisd}/domainswild2_big.txt"];
        }
        {
          tag = "geosite-cn"; type = "domain_set";
          args.files = [ "${inputs.geosite}/cn.txt" ];
        }
        {
          tag = "geosite-!cn"; type = "domain_set";
          args.files = [ "${inputs.geosite}/geolocation-!cn.txt" ];
        }
        # Upstream
        {
          tag = "upstream_google"; type = "forward";
          args.concurrent = 2;
          args.upstreams = [
            { addr = "https://8.8.8.8/dns-query"; /*enable_http3 = true;*/ }
            { addr = "https://8.8.4.4/dns-query"; /*enable_http3 = true;*/ }
          ];
        }
        {
          tag = "upstream_alidns"; type = "forward";
          args.concurrent = 2;
          args.upstreams = [
            { addr = "https://223.5.5.5/dns-query"; enable_http3 = true; }
            { addr = "https://223.6.6.6/dns-query"; enable_http3 = true; }
          ];
        }
        # Forward
        {
          tag = "forward_google"; type = "sequence";
          args = [
            { exec = "metrics_collector googledns"; }
            { exec = "$upstream_google"; }
            { exec = "query_summary googledns"; }
          ];
        }
        {
          tag = "forward_alidns"; type = "sequence";
          args = [
            { exec = "metrics_collector alidns"; }
            { exec = "$upstream_alidns"; }
            { exec = "query_summary alidns"; }
          ];
        }
        {
          tag = "fallback_alidns"; type = "sequence";
          args = [
            { exec = "metrics_collector fallback"; }
            { exec = "$forward_alidns"; }
            { exec = "query_summary fallback"; }
          ];
        }
        {
          tag = "fallback"; type = "fallback";
          args = {
            primary = "forward_google";
            secondary = "fallback_alidns";
            threshold = 5000;
          };
        }
        # Main
        {
          tag = "main"; type = "sequence";
          args = [
            # 对于国内域名, 转发到国内 DNS 以保证速度
            { matches = [ "qname $geosite-cn" ]; exec = "$forward_alidns"; }
            { matches = [ "has_resp" ]; exec = "query_summary geosite.cn"; }
            { matches = [ "has_resp" ]; exec = "accept"; }
            # 因为可能没有很好的境外 IPv6 连接能力
            { matches = [ "qname $geosite-!cn" ]; exec = "prefer_ipv4"; }
            { matches = [ "qname $geosite-!cn" ]; exec = "query_summary perfer ipv4"; }
            # 转发到境外 DNS (并 fallback)
            { exec =  "$fallback"; }
          ];
        }
        # Server
        {
          type = "udp_server";
          args = { entry = "main"; listen = "127.0.0.53:53"; };
        }
      ];
    };
  };
}
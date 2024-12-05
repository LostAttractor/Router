{ inputs, pkgs, ... }:
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
          args.files = [ "${pkgs.mosdns-geosite}/geosite_cn.txt" ];
        }
        {
          tag = "geosite-geolocation-!cn"; type = "domain_set";
          args.files = [ "${pkgs.mosdns-geosite}/geosite_geolocation-!cn.txt" ];
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

  # https://icyleaf.com/2023/08/using-vector-transform-mosdns-logging-to-grafana-via-loki/
  # https://gist.github.com/icyleaf/e98093f673b4b2850226db582447175a
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sources.mosdns-log = {
        type = "journald";
        include_units = [ "mosdns" ];
      };
      transforms.mosdns-data = {
        type = "remap";
        inputs = [ "mosdns-log" ];
        drop_on_error = true;
        source = ''
          del(.PRIORITY)
          del(.SYSLOG_FACILITY)
          del(._BOOT_ID)
          del(._CAP_EFFECTIVE)
          del(._CMDLINE)
          del(._COMM)
          del(._EXE)
          del(._GID)
          del(._MACHINE_ID)
          del(._PID)
          del(._RUNTIME_SCOPE)
          del(._STREAM_ID)
          del(._SYSTEMD_CGROUP)
          del(._SYSTEMD_INVOCATION_ID)
          del(._SYSTEMD_SLICE)
          del(._SYSTEMD_UNIT)
          del(._UID)
          del(.__MONOTONIC_TIMESTAMP)
          del(.__REALTIME_TIMESTAMP)
          del(.__SEQNUM)
          del(.__SEQNUM_ID)

          message_parts = split!(.message, r'\t')

          .timestamp = parse_timestamp!(message_parts[0], format: "%FT%T%.9fZ")
          .level = message_parts[1]

          if (length(message_parts) == 6) {
            .plugin = message_parts[2]
            .processor = message_parts[3]
            .message = message_parts[4]

            if (exists(message_parts[5])) {
              .metadata = parse_json!(message_parts[5])
              . = merge!(., .metadata)
              del(.metadata)
            }
          } else {
            .processor = message_parts[2]
            .message = message_parts[3]

            if (exists(message_parts[4])) {
              .metadata = parse_json!(message_parts[4])
              . = merge!(., .metadata)
              del(.metadata)
            }
          }

          if (exists(.query)) {
            query_parts = split!(.query, r'\s')
            .domain = query_parts[0]
            .record = query_parts[2]
            .address = query_parts[5]
          }
        '';
      };
      sinks = {
        loki = {
          type = "loki";
          inputs = [ "mosdns-data" ];
          endpoint = "http://node0-rke.local:30001";
          encoding.codec = "json";
          auth = {
            strategy = "basic";
            user = "main";
            password = "\${LOKI_TOKEN:-}";
          };
          labels = {
            app = "{{ SYSLOG_IDENTIFIER }}";
            host = "{{ host }}";
            message = "{{ message }}";
          };
          healthcheck.enabled = true;
        };
        debug = {
          type = "console";
          inputs = [ "mosdns-data" ];
          encoding.codec = "json";
        };
      };
    };
  };

  systemd.services.vector.serviceConfig.EnvironmentFile = config.sops.secrets.vector.path;
  sops.secrets.vector = {};
}
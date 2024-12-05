{ pkgs, config, ... }:
{
  systemd.services.ddns-go = {
    wantedBy = [ "multi-user.target" ];
    description = "A simple, easy-to-use DDNS service";
    serviceConfig = {
      ExecStart="${pkgs.ddns-go}/bin/ddns-go -c ${config.sops.templates."ddns-go.yaml".path} -noweb";
      Restart = "always";
      RestartSec = 120;
    };
    unitConfig = {
      StartLimitIntervalSec = 5;
      StartLimitBurst = 10;
    };
  };

  sops.templates."ddns-go.yaml".content = ''
    dnsconf:
      - ipv6:
          enable: true
          gettype: netInterface
          netinterface: ${config.network.interface.world}
          domains:
            - ns.lostattractor.net
        dns:
          name: cloudflare
          secret: ${config.sops.placeholder."ddns-go/cloudflare/secret"}
  '';

  sops.secrets."ddns-go/cloudflare/secret" = {};
}
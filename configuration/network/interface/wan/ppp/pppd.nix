{ config, network, ... }:
{
  services.pppd = {
    enable = true;
    peers.edpnet = {
      enable = true;
      configFile = config.sops.templates."edpnet".path;
    };
  };

  sops.templates."edpnet".content = ''
    plugin pppoe.so ${network.interface.wan}

    name "${config.sops.placeholder."network/pppoe/name"}"
    password "${config.sops.placeholder."network/pppoe/password"}"
    ifname ${network.interface.ppp}

    usepeerdns
    defaultroute  # v4默认路由
  '';

  sops.secrets."network/pppoe/name" = {};
  sops.secrets."network/pppoe/password" = {};
}
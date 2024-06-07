{ config, ... }:
{
  # TODO: 安全问题? 毕竟现在inbound全部允许
  services.miniupnpd = {
    enable = true;
    natpmp = true;
    externalInterface = config.network.interface.world;
    internalIPs = [ config.network.interface.private.lan ];
  };
}
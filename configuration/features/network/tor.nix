{ lib, ... }:
{
  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
      # transparentProxy.enable = true;
    };
    # settings.TransProxyType = "TPROXY";
  };

  # systemd.services.tor.serviceConfig = {
  #   AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
  #   CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
  #   NoNewPrivileges = lib.mkForce false;
  # };
}
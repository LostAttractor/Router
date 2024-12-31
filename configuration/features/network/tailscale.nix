{ network, config, pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.tailscale.path;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
      "--accept-routes"
      "--advertise-routes=10.0.0.0/16,10.1.0.0/16,10.10.0.0/16,10.100.0.0/16,10.255.0.0/16,fd7a:115c:a1e0:b1a:0:1:a00:0/104,fd23:3333:3333::/48"
    ];
  };

  sops.secrets.tailscale = {};

  network.interface.private.tailscale = network.interface.tailscale;
}
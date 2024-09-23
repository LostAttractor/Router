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

  # https://nixos.wiki/wiki/Networkd-dispatcher
  services.networkd-dispatcher = {
    enable = true;
    rules = {
      "50-tailscale" = {
        onState = [ "routable" ];
        # https://www.kernel.org/doc/html/latest/networking/segmentation-offloads.html
        # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
        script = ''
          #!${pkgs.runtimeShell}
          ${pkgs.ethtool}/bin/ethtool -K $IFACE rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
  };

  sops.secrets.tailscale = {};

  network.interface.private.tailscale = network.interface.tailscale;
}
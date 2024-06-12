{ network, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  network.interface.private.tailscale = network.interface.tailscale;
}
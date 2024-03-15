_:
{
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };
}
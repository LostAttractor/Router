_:
{
  services.prometheus.exporters = {
    node = {
      enable = true;
    };

    dnsmasq = {
      enable = true;
      leasesPath = "/var/lib/dnsmasq/dnsmasq.leases";
    };
  };
}
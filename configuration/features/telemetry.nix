_:
{
  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = true;
    };

    dnsmasq = {
      enable = true;
      openFirewall = true;
      leasesPath = "/var/lib/dnsmasq/dnsmasq.leases";
    };
  };
}
_: {
  services.prometheus.exporters = {
    dnsmasq = {
      enable = true;
      leasesPath = "/var/lib/dnsmasq/dnsmasq.leases";
    };
  };
}
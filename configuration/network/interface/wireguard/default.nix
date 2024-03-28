{ config, network, ... }:
{
  systemd.network = {
    netdevs."50-${network.interface.wg}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = network.interface.wg;
      };
      wireguardConfig = {
        # pubkey: vuDPg3CcJH60zEBCBwBpKdzqW7oLtZChWynTKFh6SkU=
        PrivateKeyFile = config.sops.secrets."network/wireguard/privkey".path;
        ListenPort = 51820;
      };
      wireguardPeers = [
        { wireguardPeerConfig = {
          PublicKey = "WLfPF6oBHGdZkq0ZkPVQSlkfnEiFU1+xtqNT7W7rRjw=";
          AllowedIPs = [ "10.255.0.2" ];
        };}
        { wireguardPeerConfig = {
          PublicKey = "RAqne2m36M6i48XDa9kBmfjGR/EsgYm6xsJte75DVhA=";
          AllowedIPs = [ "10.255.0.3" ];
        };}
      ];
    };
    networks."50-${network.interface.wg}" = {
      name = network.interface.wg;
      address = [ "10.255.0.1/24" ];
      networkConfig.IPMasquerade = "ipv4";
    };
  };

  network.nftables.interface.vpn = network.interface.wg;

  sops.secrets."network/wireguard/privkey" = { 
    mode = "0440";
    group = "systemd-network";
  };
}

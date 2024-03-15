{ config, ... }:
{
  systemd.network = {
    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
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
    networks."50-wg0" = {
      name = "wg0";
      address = [ "10.255.0.1/24" ];
      networkConfig.IPMasquerade = "ipv4";
    };
  };

  network.nftables.interface.vpn = "wg0";

  sops.secrets."network/wireguard/privkey" = { 
    mode = "0440";
    group = "systemd-network";
  };
}

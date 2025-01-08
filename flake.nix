{
  description = "ChaosAttractor's Router Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    daeuniverse.url = "github:daeuniverse/flake.nix/unstable";
    daeuniverse.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    oisd = { url = "github:sjhgvr/oisd"; flake = false; };
    v2ray-rules-dat = { url = "github:Loyalsoldier/v2ray-rules-dat/release"; flake = false; };
    homelab.url = "github:lostattractor/homelab";
    homelab.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, deploy-rs, ... } @ inputs : 
  let
    network = {
      interface = rec {
        # Physics
        downstream = "enp1s0f0np0";
        upstream = "enp1s0f1np1";
        # Layer 2 encapsulated
        lan = "lan";  # VLAN 1 on downstream
        direct = "direct"; # VLAN 2 on downstream
        security = "security"; # VLAN 10 on downstream
        manage = "manage"; # VLAN 100 on downstream
        onu = upstream; # Untagged on upstream / VLAN 4094 on downstream
        ppp = "pppoe-wan"; # PPP on upstream
        # Bridges
        br-lan = "br-lan";
        # SDN
        wg = "wg0"; # Wireguard
        tailscale = "tailscale0"; # Tailscale
      };
      domain = "home.lostattractor.net";
    };
  in rec {
    # Router@NUC9.home.lostattractor.net
    nixosConfigurations."router" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = { inherit inputs network; };
      modules = [
        ./configuration
        (inputs.homelab + "/hardware/kvm/proxmox.nix")
        { networking.hostName = "router"; }
        inputs.sops-nix.nixosModules.sops
        inputs.daeuniverse.nixosModules.dae
        { services.dae.package = inputs.daeuniverse.packages.${system}.dae-experiment; }
        inputs.vscode-server.nixosModules.default
        ./modules/mosdns
        {
          nixpkgs.overlays = [
            (final: prev: with prev;  {
              mosdns = callPackage ./packages/mosdns { buildGoModule = pkgs.buildGo123Module; };
              v2dat = callPackage ./packages/v2dat { buildGoModule = pkgs.buildGo123Module; };
              v2dat-geoip = (callPackage ./packages/geoip { v2ray-rules-dat = inputs.v2ray-rules-dat; });
              v2dat-geosite = (callPackage ./packages/geosite { v2ray-rules-dat = inputs.v2ray-rules-dat; });
              mosdns-geosite = (callPackage ./packages/mosdns-geosite { v2ray-rules-dat = inputs.v2ray-rules-dat; });
            })
          ];
        }
      ];
    };

    # Deploy-RS Configuration
    deploy = {
      sshUser = "root";
      magicRollback = false;

      nodes."router@nuc9.home.lostattractor.net" = {
        hostname = "router.home.lostattractor.net";
        profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations."router";
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

    hydraJobs = with nixpkgs.lib; {
      nixosConfigurations = mapAttrs' (name: config:
        nameValuePair name config.config.system.build.toplevel)
        nixosConfigurations;
      image = mapAttrs' (name: config:
        nameValuePair name config.config.system.build.image)
        nixosConfigurations;
    };
  };
}

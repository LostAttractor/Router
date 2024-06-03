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
    eh5.url = "github:EHfive/flakes";
    eh5.inputs.nixpkgs.follows = "nixpkgs";
    oisd = { url = "github:sjhgvr/oisd"; flake = false; };
    geosite = { url = "github:v2fly/domain-list-community/release"; flake = false; };
  };

  outputs = { nixpkgs, deploy-rs, ... } @ inputs : 
  let
    network.interface = rec {
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
      # SDN
      wg = "wg0"; # Wireguard
    };
  in rec {
    # Router@NUC9.home.lostattractor.net
    nixosConfigurations."router" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs network; };
      modules = [
        ./hardware/kvm
        ./configuration
        { networking.hostName = "router"; }
        inputs.sops-nix.nixosModules.sops
        inputs.daeuniverse.nixosModules.dae
        inputs.eh5.nixosModules.mosdns
        { nixpkgs.overlays = [ inputs.eh5.overlays.default ]; }
        { nixpkgs.overlays = [ inputs.eh5.overlay ]; }
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
      VMA = mapAttrs' (name: config:
        nameValuePair name config.config.system.build.VMA)
        nixosConfigurations;
    };
  };
}

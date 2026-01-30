{
  description = "V10 HARDWARE APP BUILDING STUDIO (Local Environment)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, microvm }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # THE BATTLE-TESTED ROSETTA BLUEPRINT (Evaluation-Safe)
      nixosConfigurations.v10-twin = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux"; # The Digital Twin target
        modules = [
          microvm.nixosModules.microvm
          {
            networking.hostName = "v10-twin";
            system.stateVersion = "24.05";
            
            # HYPERVISOR & ROSETTA (Native Silicon Acceleration)
            microvm.hypervisor = "vfkit";
            microvm.vfkit.rosetta.enable = true;
            microvm.vfkit.rosetta.install = true;

            # OPTIMIZATION: Host Nix Store Sharing (Prevents RAM crashes)
            microvm.shares = [
              {
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "store";
                proto = "virtiofs";
              }
              {
                source = "/Users/johnny/Code/gcp/v10-local-builder";
                mountPoint = "/mnt/project";
                tag = "project";
                proto = "virtiofs";
              }
            ];

            # USER-MODE NETWORKING (Sudo-less)
            microvm.interfaces = [ {
              type = "user";
              id = "vm-net";
              mac = "02:00:00:00:00:01";
            } ];

            services.getty.autologinUser = "root";
            environment.systemPackages = [ 
              pkgs.htop 
              pkgs.git 
              pkgs.file
              # Native ARM64 cross-eval check
              pkgs.pkgsCross.gnu64.hello 
            ];
          }
        ];
      };

      # THE ROBUST RUNNER (Exposed as a package for the host)
      packages.${system}.microvm = self.nixosConfigurations.v10-twin.config.microvm.declaredRunner;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.aider-chat
          pkgs.ollama
          pkgs.git
          pkgs.ttyd
          pkgs.python311Packages.websockify
          pkgs.vfkit
        ];

        shellHook = ''
          export STUDIO_MODE="v10-local-builder"
          echo "--- V10 NIXOS HARDWARE APP BUILDING STUDIO ---"
          echo "Architecture: APPLE SILICON + ROSETTA 2"
          echo "Run: 'nix run .#microvm' to boot the digital twin"
        '';
      };
    };
}

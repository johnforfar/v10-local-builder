{
  description = "V10 HARDWARE APP BUILDING STUDIO (Local Environment)";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    
    # Ecosystem Sync (External Inputs)
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";

    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    # nixai placeholder or input if available
    # nixai.url = "github:nix-community/nixai"; 
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      llm-agents,
      microvm,
    }:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = eachSystem (
        { pkgs, system, ... }:
        {
          # V10 Local Development Shell
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.aider-chat
              pkgs.ollama
              pkgs.git
              pkgs.nix-prefetch-git
              # Hardware debugging & virtualization tools
              pkgs.usbutils
              pkgs.pciutils
              pkgs.qemu
              pkgs.vfkit # for M1 Mac MicroVM support
            ];

            shellHook = ''
              export STUDIO_MODE="v10-local-builder"
              export ARCHITECT="ollama/glm-4.7-flash:q4_K_M"
              export EDITOR="ollama/glm-4.7-flash:q4_K_M"
              
              echo "--- V10 NIXOS HARDWARE APP BUILDING STUDIO (LOCAL) ---"
              echo "OS: macOS M1 (Ready for MicroVM via vfkit)"
              echo "Model Stack: GLM-4.7-Flash (Unified)"
              echo "Ecosystem: llm-agents + microvm.nix"
              echo "Working Dir: v10-local-builder"
            '';
          };
        }
      );
    };
}

{
  description = "ChezWizper - Voice transcription tool for Wayland/Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # System-specific outputs
      systemOutputs = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          
          # Override whisper-cpp to disable CUDA support to avoid segfaults
          whisper-cpp-no-cuda = pkgs.whisper-cpp.override {
            cudaSupport = false;
          };
          
          # Import our package definition with custom whisper-cpp
          chezwizper = pkgs.callPackage ./nix/package.nix { 
            whisper-cpp = whisper-cpp-no-cuda;
          };
          
          # Import our devshell
          devShell = import ./nix/devshell.nix { inherit pkgs; };
        in
        {
          # The main package
          packages = {
            default = chezwizper;
            chezwizper = chezwizper;
          };

          # Development shell
          devShells.default = devShell;

          # App definition for `nix run`
          apps.default = {
            type = "app";
            program = "${chezwizper}/bin/chezwizper";
          };
        }
      );

      # System-independent outputs
      globalOutputs = {
        # NixOS module
        nixosModules = {
          default = ./nix/module.nix;
          chezwizper = ./nix/module.nix;
        };

        # Overlay for easy integration
        overlays.default = final: prev: {
          chezwizper = final.callPackage ./nix/package.nix { 
            whisper-cpp = final.whisper-cpp.override {
              cudaSupport = false;
            };
          };
        };
      };
    in
    systemOutputs // globalOutputs;
}

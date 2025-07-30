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
          
          # Updated whisper-cpp with specific commit to fix nixpkgs issues
          whisperUpdated = pkgs.whisper-cpp.overrideAttrs (oldAttrs: {
            src = pkgs.fetchFromGitHub {
              owner = "ggml-org";
              repo = "whisper.cpp";
              rev = "a8d002cfd879315632a579e73f0148d06959de36";
              sha256 = "sha256-dppBhiCS4C3ELw/Ckx5W0KOMUvOHUiisdZvkS7gkxj4=";
            };
          });
          
          # Import our package definition with updated whisper-cpp
          chezwizper = pkgs.callPackage ./nix/package.nix { 
            whisper-cpp = whisperUpdated;
          };
          
          # Import our devshell with updated whisper-cpp
          devShell = import ./nix/devshell.nix { 
            inherit pkgs; 
            whisper-cpp = whisperUpdated;
          };
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
          # Updated whisper-cpp with specific commit to fix nixpkgs issues
          whisper-cpp = prev.whisper-cpp.overrideAttrs (oldAttrs: {
            src = final.fetchFromGitHub {
              owner = "ggml-org";
              repo = "whisper.cpp";
              rev = "a8d002cfd879315632a579e73f0148d06959de36";
              sha256 = "sha256-dppBhiCS4C3ELw/Ckx5W0KOMUvOHUiisdZvkS7gkxj4=";
            };
          });
          
          chezwizper = final.callPackage ./nix/package.nix { 
            whisper-cpp = final.whisper-cpp;
          };
        };
      };
    in
    systemOutputs // globalOutputs;
}

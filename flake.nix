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
          
          # Import our package definition with standard whisper-cpp
          chezwizper = pkgs.callPackage ./nix/package.nix { };
          
          # Whisper models packages (optional)
          whisper-models-base = pkgs.callPackage ./nix/whisper-models.nix { 
            models = [ "base" ];
          };
          whisper-models-small = pkgs.callPackage ./nix/whisper-models.nix { 
            models = [ "base" "small" ];
          };
          whisper-models-large = pkgs.callPackage ./nix/whisper-models.nix { 
            models = [ "base" "small" "large-v3" ];
          };
          
          # Import our devshell
          devShell = import ./nix/devshell.nix { 
            inherit pkgs;
          };
        in
        {
          # The main package
          packages = {
            default = chezwizper;
            chezwizper = chezwizper;
            
            # Whisper models packages
            whisper-models-base = whisper-models-base;
            whisper-models-small = whisper-models-small;
            whisper-models-large = whisper-models-large;
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

        # Home Manager module
        homeManagerModules = {
          default = ./nix/home-module.nix;
          chezwizper = ./nix/home-module.nix;
        };

        # Overlay for easy integration
        overlays.default = final: prev: {
          chezwizper = final.callPackage ./nix/package.nix { };
        };
      };
    in
    systemOutputs // globalOutputs;
}

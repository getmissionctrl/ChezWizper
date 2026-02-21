{
  description = "ChezWizper - Voice transcription tool for Wayland/Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    moonshine.url = "path:../moonshine";
  };

  outputs = { self, nixpkgs, flake-utils, moonshine }:
    let
      # System-specific outputs
      systemOutputs = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          moonshine-cli = moonshine.packages.${system}.moonshine-cli;
          moonshine-pkg = moonshine.packages.${system}.moonshine;

          # Import our package definition
          chezwizper = pkgs.callPackage ./nix/package.nix {
            inherit moonshine-cli;
            moonshine = moonshine-pkg;
          };

          # Import our devshell
          devShell = import ./nix/devshell.nix {
            inherit pkgs moonshine-cli;
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

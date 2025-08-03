# Example NixOS configuration for ChezWizper
{ config, pkgs, ... }:

{
  # For NixOS system configuration
  imports = [ ./module.nix ];

  services.chezwizper = {
    enable = true;
    
    # Model configuration
    whisper = {
      model = "base"; # Options: tiny, base, small, medium, large-v1, large-v2, large-v3
      language = "en"; # Language code for transcription
      # modelPath = "/path/to/custom/model.bin"; # Optional: use custom model path
    };

    # Audio configuration
    audio = {
      device = "default";
      sampleRate = 16000;
      channels = 1;
    };

    # UI configuration
    ui = {
      indicatorPosition = "top-right";
      indicatorSize = 20;
      showNotifications = true;
      layerShellAnchor = "top | right";
      layerShellMargin = 10;
    };

    # Wayland configuration
    wayland = {
      inputMethod = "wtype"; # Options: wtype, ydotool
      useHyprlandIpc = true;
    };

    # Behavior configuration
    behavior = {
      autoPaste = true;
      preserveClipboard = false;
      deleteAudioFiles = true;
    };

    # Server configuration
    port = 3737;
    logLevel = "info"; # Options: debug, info, warn, error

    # Hyprland keybind configuration
    hyprland = {
      enable = true;
      keybind = "SUPER, W"; # Default keybind, change to "CTRL SHIFT, R" or any other
    };
  };
}

# Example Home Manager configuration for ChezWizper
# Add this to your home.nix or home-manager configuration
#
# { config, pkgs, ... }:
# 
# {
#   imports = [ ./home-module.nix ];
# 
#   services.chezwizper = {
#     enable = true;
#     
#     whisper = {
#       model = "base";
#       language = "en";
#     };
# 
#     hyprland = {
#       enable = true;
#       keybind = "SUPER, W";
#     };
#   };
# 
#   # If using Hyprland through Home Manager
#   wayland.windowManager.hyprland = {
#     enable = true;
#     # The keybind will be automatically added when chezwizper.hyprland.enable = true
#   };
# }
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.chezwizper;
  
  # Determine the model file path
  modelFileName = "ggml-${cfg.whisper.model}.bin";
  modelPath = 
    if cfg.whisper.modelPath != null then 
      cfg.whisper.modelPath
    else 
      "${config.xdg.dataHome}/chezwizper/models/${modelFileName}";
  
  configFile = pkgs.writeText "chezwizper-config.toml" ''
    [audio]
    device = "${cfg.audio.device}"
    sample_rate = ${toString cfg.audio.sampleRate}
    channels = ${toString cfg.audio.channels}

    [whisper]
    model = "${cfg.whisper.model}"
    language = "${cfg.whisper.language}"
    command_path = "${cfg.whisper-cpp}/bin/whisper-cpp"
    model_path = "${modelPath}"

    [ui]
    indicator_position = "${cfg.ui.indicatorPosition}"
    indicator_size = ${toString cfg.ui.indicatorSize}
    show_notifications = ${boolToString cfg.ui.showNotifications}
    layer_shell_anchor = "${cfg.ui.layerShellAnchor}"
    layer_shell_margin = ${toString cfg.ui.layerShellMargin}

    [wayland]
    input_method = "${cfg.wayland.inputMethod}"
    use_hyprland_ipc = ${boolToString cfg.wayland.useHyprlandIpc}

    [behavior]
    auto_paste = ${boolToString cfg.behavior.autoPaste}
    preserve_clipboard = ${boolToString cfg.behavior.preserveClipboard}
    delete_audio_files = ${boolToString cfg.behavior.deleteAudioFiles}

    [server]
    port = ${toString cfg.port}
  '';

  chezwizperPackage = cfg.package.override {
    inherit (cfg) whisper-cpp;
  };
in
{
  options.services.chezwizper = {
    enable = mkEnableOption "ChezWizper voice transcription service";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = literalExpression "pkgs.chezwizper";
      description = "The ChezWizper package to use";
    };

    whisper-cpp = mkOption {
      type = types.package;
      default = pkgs.whisper-cpp;
      defaultText = literalExpression "pkgs.whisper-cpp";
      description = "The whisper-cpp package to use";
    };

    audio = {
      device = mkOption {
        type = types.str;
        default = "default";
        description = "Audio device to use for recording";
      };

      sampleRate = mkOption {
        type = types.int;
        default = 16000;
        description = "Audio sample rate";
      };

      channels = mkOption {
        type = types.int;
        default = 1;
        description = "Number of audio channels";
      };
    };

    whisper = {
      model = mkOption {
        type = types.str;
        default = "base";
        description = "Whisper model to use (e.g., tiny, base, small, medium, large)";
      };

      language = mkOption {
        type = types.str;
        default = "en";
        description = "Language code for transcription";
      };

      modelPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to whisper model file (auto-downloads if null)";
        example = "~/.local/share/chezwizper/models/ggml-base.bin";
      };
    };

    ui = {
      indicatorPosition = mkOption {
        type = types.str;
        default = "top-right";
        description = "Position of the recording indicator";
      };

      indicatorSize = mkOption {
        type = types.int;
        default = 20;
        description = "Size of the recording indicator";
      };

      showNotifications = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to show notifications";
      };

      layerShellAnchor = mkOption {
        type = types.str;
        default = "top | right";
        description = "Layer shell anchor position";
      };

      layerShellMargin = mkOption {
        type = types.int;
        default = 10;
        description = "Layer shell margin";
      };
    };

    wayland = {
      inputMethod = mkOption {
        type = types.enum [ "wtype" "ydotool" ];
        default = "wtype";
        description = "Text injection method to use";
      };

      useHyprlandIpc = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use Hyprland IPC for notifications";
      };
    };

    behavior = {
      autoPaste = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to automatically paste transcribed text";
      };

      preserveClipboard = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to preserve clipboard content";
      };

      deleteAudioFiles = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to delete audio files after transcription";
      };
    };

    port = mkOption {
      type = types.port;
      default = 3737;
      description = "Port for the HTTP API server";
    };

    logLevel = mkOption {
      type = types.str;
      default = "info";
      description = "Log level (e.g., debug, info, warn, error)";
    };

    hyprland = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to configure Hyprland keybind for ChezWizper";
      };

      keybind = mkOption {
        type = types.str;
        default = "SUPER, W";
        example = "CTRL SHIFT, R";
        description = "Keybind to toggle ChezWizper recording in Hyprland";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install the package
    home.packages = [ chezwizperPackage ];

    # Setup systemd user service
    systemd.user.services.chezwizper = {
      Unit = {
        Description = "ChezWizper Voice Transcription Service";
        Documentation = [ "https://github.com/silvabyte/ChezWizper" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${chezwizperPackage}/bin/chezwizper";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "RUST_LOG=${cfg.logLevel}"
        ];

        # Security settings
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [
          "%h/.config/chezwizper"
          "%h/.local/share/chezwizper"
          "%t"
        ];

        # Resource limits
        MemoryLimit = "6G";
        CPUQuota = "80%";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Create config directories and download model
    systemd.user.services.chezwizper-setup = {
      Unit = {
        Description = "ChezWizper initial setup";
        Before = [ "chezwizper.service" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "chezwizper-setup" ''
          # Create directories
          mkdir -p $HOME/.config/chezwizper
          mkdir -p ${config.xdg.dataHome}/chezwizper/models
          
          # Copy configuration
          cp ${configFile} $HOME/.config/chezwizper/config.toml
          
          # Download model if needed
          ${optionalString (cfg.whisper.modelPath == null) ''
            MODEL_FILE="${config.xdg.dataHome}/chezwizper/models/${modelFileName}"
            if [ ! -f "$MODEL_FILE" ]; then
              echo "Downloading whisper model ${cfg.whisper.model}..."
              cd ${config.xdg.dataHome}/chezwizper/models
              ${cfg.whisper-cpp}/bin/whisper-cpp-download-ggml-model ${cfg.whisper.model}
            fi
          ''}
        '';
      };

      Install = {
        WantedBy = [ "chezwizper.service" ];
      };
    };

    # Configure Hyprland keybind if enabled
    wayland.windowManager.hyprland.settings = mkIf (cfg.hyprland.enable && config.wayland.windowManager.hyprland.enable or false) {
      bind = [
        "${cfg.hyprland.keybind}, exec, ${pkgs.curl}/bin/curl -X POST http://127.0.0.1:${toString cfg.port}/toggle"
      ];
    };

    # Create a convenience script
    home.file.".local/bin/chezwizper-toggle" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        ${pkgs.curl}/bin/curl -X POST http://127.0.0.1:${toString cfg.port}/toggle
      '';
    };
  };
}
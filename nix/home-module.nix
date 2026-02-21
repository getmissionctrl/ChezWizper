{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.chezwizper;

  configFile = pkgs.writeText "chezwizper-config.toml" ''
    [audio]
    device = "${cfg.audio.device}"
    sample_rate = ${toString cfg.audio.sampleRate}
    channels = ${toString cfg.audio.channels}

    [whisper]
    model = "base-en"
    language = "${cfg.whisper.language}"

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
    inherit (cfg) moonshine-cli moonshine;
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

    moonshine-cli = mkOption {
      type = types.package;
      description = "The moonshine-cli package to use";
    };

    moonshine = mkOption {
      type = types.package;
      description = "The moonshine package (provides bundled models)";
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
      language = mkOption {
        type = types.str;
        default = "en";
        description = "Language code for transcription";
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

        # Minimal security settings to allow desktop session access
        ReadWritePaths = [
          "%h/.config/chezwizper"
          "%h/.local/share/chezwizper"
          "%t"
        ];

        # Resource limits
        MemoryLimit = "2G";
        CPUQuota = "80%";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Create config directory and copy config
    systemd.user.services.chezwizper-setup = {
      Unit = {
        Description = "ChezWizper initial setup";
        Before = [ "chezwizper.service" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "chezwizper-setup" ''
          mkdir -p $HOME/.config/chezwizper
          cp ${configFile} $HOME/.config/chezwizper/config.toml
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

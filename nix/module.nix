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
    model = "${cfg.whisper.model}"
    language = "${cfg.whisper.language}"
    ${optionalString (cfg.whisper.commandPath != null) ''command_path = "${cfg.whisper.commandPath}"''}
    ${optionalString (cfg.whisper.modelPath != null) ''model_path = "${cfg.whisper.modelPath}"''}

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

      commandPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom path to whisper CLI (uses whisper-cpp from package if null)";
      };

      modelPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to whisper model file (required for whisper.cpp)";
        example = "/var/lib/chezwizper/models/ggml-base.bin";
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
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.whisper.modelPath != null || cfg.whisper.commandPath == null;
        message = "ChezWizper: modelPath must be set when using the default whisper-cpp";
      }
    ];

    systemd.user.services.chezwizper = {
      description = "ChezWizper Voice Transcription Service";
      documentation = [ "https://github.com/matsilva/whispy" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "default.target" ];

      environment = {
        RUST_LOG = cfg.logLevel;
        XDG_CONFIG_HOME = "%h/.config";
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${chezwizperPackage}/bin/chezwizper";
        Restart = "always";
        RestartSec = 5;

        # Security and resource limits
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ "%h/.config/chezwizper" "%t" ];
        
        # Whisper models require significant memory
        MemoryLimit = "6G";
        CPUQuota = "80%";

        # Required for audio access
        SupplementaryGroups = [ "audio" ];
      };

      preStart = ''
        mkdir -p $HOME/.config/chezwizper
        cp ${configFile} $HOME/.config/chezwizper/config.toml
      '';
    };

    # Ensure the user is in the audio group
    users.users.${config.users.users.${config.services.chezwizper.user or config.users.users.${config.users.users.default or "root"}.name}.name}.extraGroups = [ "audio" ];
  };
}
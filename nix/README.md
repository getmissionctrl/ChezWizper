# ChezWizper Nix Flake

This directory contains the Nix flake configuration for ChezWizper, providing:
- Reproducible builds
- NixOS service module
- Development environment
- Easy installation and deployment

## Quick Start

### Using the Flake

1. **Run directly** (without installing):
   ```bash
   nix run github:yourusername/chezwizper
   ```

2. **Install to profile**:
   ```bash
   nix profile install github:yourusername/chezwizper
   ```

3. **Development shell**:
   ```bash
   nix develop
   # or with direnv
   echo "use flake" > .envrc && direnv allow
   ```

### Download Whisper Models

ChezWizper requires Whisper models for transcription. Use the helper script:

```bash
# In development shell or after installation
./nix/download-models.sh base  # Download base model (74 MB, recommended for testing)
./nix/download-models.sh large-v3-turbo  # Download turbo model (809 MB, best quality/speed)
```

## NixOS Module

### Basic Configuration

Add to your NixOS configuration:

```nix
{
  inputs.chezwizper.url = "github:yourusername/chezwizper";
  
  outputs = { self, nixpkgs, chezwizper, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        chezwizper.nixosModules.default
        {
          services.chezwizper = {
            enable = true;
            whisper.modelPath = "/var/lib/chezwizper/models/ggml-base.bin";
          };
        }
      ];
    };
  };
}
```

### Full Configuration Example

```nix
services.chezwizper = {
  enable = true;
  
  # Audio settings
  audio = {
    device = "default";
    sampleRate = 16000;
    channels = 1;
  };
  
  # Whisper configuration
  whisper = {
    model = "base";
    language = "en";
    modelPath = "/var/lib/chezwizper/models/ggml-base.bin";
    # commandPath = "/custom/path/to/whisper";  # Optional: override whisper binary
  };
  
  # UI settings
  ui = {
    indicatorPosition = "top-right";
    indicatorSize = 20;
    showNotifications = true;
  };
  
  # Wayland settings
  wayland = {
    inputMethod = "wtype";  # or "ydotool"
    useHyprlandIpc = true;
  };
  
  # Behavior settings
  behavior = {
    autoPaste = true;
    preserveClipboard = false;
    deleteAudioFiles = true;
  };
  
  # Service settings
  port = 3737;
  logLevel = "info";
};
```

### Setting up Models for NixOS Service

1. Create model directory:
   ```bash
   sudo mkdir -p /var/lib/chezwizper/models
   ```

2. Download models:
   ```bash
   sudo ./nix/download-models.sh -d /var/lib/chezwizper/models base
   ```

3. Set proper permissions:
   ```bash
   sudo chown -R yourusername:users /var/lib/chezwizper
   ```

## Development

### Building

```bash
nix build
./result/bin/chezwizper
```

### Development Shell

The development shell includes all build and runtime dependencies:

```bash
nix develop
cargo build
cargo run
```

Available tools in dev shell:
- Rust toolchain (cargo, rustc, clippy, rustfmt, rust-analyzer)
- Runtime dependencies (whisper-cpp, wtype, wl-clipboard, etc.)
- Development tools (cargo-watch, cargo-edit, pre-commit)

### Testing Different Whisper Implementations

The flake uses `whisper-cpp` from nixpkgs by default. To test with a custom whisper:

1. Override in configuration:
   ```nix
   services.chezwizper.whisper.commandPath = "/path/to/custom/whisper";
   ```

2. Or set in config file:
   ```toml
   [whisper]
   command_path = "/path/to/custom/whisper"
   ```

## Overlay Usage

Add ChezWizper to your system packages using the overlay:

```nix
{
  nixpkgs.overlays = [ chezwizper.overlays.default ];
  environment.systemPackages = with pkgs; [ chezwizper ];
}
```

## Hyprland Integration

Add to your Hyprland configuration:

```conf
bind = SUPER, R, exec, curl -X POST http://127.0.0.1:3737/toggle
```

## Troubleshooting

### Service won't start
- Check logs: `journalctl --user -u chezwizper -e`
- Ensure model file exists at configured path
- Verify user is in audio group: `groups | grep audio`

### No audio recording
- Check audio permissions: `arecord -l`
- Try different audio device in config
- Ensure PulseAudio/PipeWire is running

### Transcription fails
- Verify model file is downloaded completely
- Check available system memory (large models need 3-5GB)
- Try a smaller model (tiny or base)

### Text injection issues
- Ensure wtype is installed for Wayland
- For ydotool, check that ydotoold daemon is running
- Try toggling `autoPaste` in configuration

## Package Structure

- `package.nix` - Main package definition with all dependencies
- `module.nix` - NixOS service module with systemd configuration
- `devshell.nix` - Development environment setup
- `download-models.sh` - Helper script to download Whisper models

## Dependencies

The flake automatically includes:
- **Build**: cargo, rustc, pkg-config, alsa-lib, libxkbcommon
- **Runtime**: whisper-cpp, wtype, wl-clipboard, curl, hyprland (optional)
- **Audio**: ALSA libraries and audio group membership

All dependencies are pinned to ensure reproducible builds.
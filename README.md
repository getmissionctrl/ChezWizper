# ChezWizper

Voice transcription tool for Wayland/Hyprland. Press a keybind to toggle recording, get automatic transcription via Whisper, and inject text into the focused application.

📚 **[View Documentation](./docs/index.md)** - Detailed guides and configuration

## Quick Install (Omarchy + Arch Linux)

```bash
git clone https://github.com/silvabyte/ChezWizper.git
cd ChezWizper
make install
```

This automatically installs dependencies, builds ChezWizper with optimized Whisper, sets up services, and configures keybinds.

**After installation:**
1. Start the service: `make start`
2. Add to Hyprland config: `bind = SUPER, R, exec, curl -X POST http://127.0.0.1:3737/toggle`
3. Press Super+R to start recording!

## Features

- 🎤 Keybind-activated voice recording
- 🔴 Visual recording indicators  
- 🎯 Automatic text injection into focused apps
- 📋 Intelligent clipboard fallback
- ⚡ Optimized for Wayland/Hyprland
- 🔧 Configurable via TOML

## Manual Installation

For other distributions or custom setups, see the [Installation Guide](./docs/installation.md).

## Configuration

Default config at `~/.config/chezwizper/config.toml`. See [Configuration Guide](./docs/audio-configuration.md) for details.

## Nix Installation

ChezWizper is available as a Nix flake with NixOS and Home Manager modules.

### Using as a Flake Input

Add ChezWizper to your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chezwizper.url = "github:silvabyte/ChezWizper";
  };

  outputs = { self, nixpkgs, chezwizper, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        chezwizper.nixosModules.default
        {
          services.chezwizper = {
            enable = true;
            whisper.model = "base";  # or tiny, small, medium, large
            hyprland = {
              enable = true;
              keybind = "SUPER, W";  # or "CTRL SHIFT, R"
            };
          };
        }
      ];
    };
  };
}
```

### Home Manager Module

For Home Manager users:

```nix
{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    chezwizper.url = "github:silvabyte/ChezWizper";
  };

  outputs = { self, nixpkgs, home-manager, chezwizper, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      modules = [
        chezwizper.homeManagerModules.default
        {
          services.chezwizper = {
            enable = true;
            whisper.model = "base";
            hyprland.keybind = "SUPER, W";
          };
        }
      ];
    };
  };
}
```

### Configuration Options

Key configuration options:

```nix
services.chezwizper = {
  enable = true;
  
  # Whisper model configuration
  whisper = {
    model = "base";     # tiny, base, small, medium, large-v1/v2/v3
    language = "en";    # Language code
  };
  
  # Hyprland integration
  hyprland = {
    enable = true;
    keybind = "SUPER, W";  # Your preferred keybind
  };
  
  # Audio settings
  audio = {
    device = "default";
    sampleRate = 16000;
  };
  
  # UI preferences
  ui = {
    showNotifications = true;
    indicatorPosition = "top-right";
  };
};
```

The module will automatically:
- Download the specified Whisper model on first use
- Configure the systemd service
- Set up Hyprland keybinds (if enabled)
- Create the configuration file

### Building Locally

```bash
# Build the package
nix build .#chezwizper

# Run directly
nix run .#chezwizper
```

## Development

ChezWizper uses a Makefile for common tasks:

```bash
make build      # Build debug binary
make release    # Build optimized release
make test       # Run tests
make lint       # Run clippy linter
make fmt        # Check formatting
make fix        # Fix formatting and simple issues

make start      # Enable and start service
make logs       # Show service logs
make restart    # Restart service
make status     # Check service status
make clean      # Clean build artifacts
```

## Troubleshooting

- **Recording issues**: Check [Audio Configuration](./docs/audio-configuration.md)
- **Text injection fails**: See [Text Injection Setup](./docs/text-injection-setup.md)
- **Service problems**: View logs with `make logs`

## Updates

```bash
chezwizper-update                    # Update ChezWizper
chezwizper-update --whisper          # Update both ChezWizper and Whisper
chezwizper-update --check            # Check for updates
```

## License

MIT
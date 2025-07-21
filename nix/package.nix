{ lib
, stdenv
, rustPlatform
, pkg-config
, alsa-lib
, libxkbcommon
, whisper-cpp
, openai-whisper
, wtype
, ydotool
, wl-clipboard
, curl
, hyprland
, makeWrapper
}:

rustPlatform.buildRustPackage rec {
  pname = "chezwizper";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./..;
    filter = path: type:
      let
        baseName = baseNameOf path;
      in
      !(lib.hasSuffix "flake.nix" path ||
        lib.hasSuffix "flake.lock" path ||
        baseName == "nix" ||
        baseName == ".direnv" ||
        baseName == "result" ||
        baseName == ".envrc");
  };

  cargoLock = {
    lockFile = ../Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    libxkbcommon
  ];

  # Runtime dependencies that need to be in PATH
  runtimeDeps = [
    whisper-cpp
    openai-whisper
    wtype
    wl-clipboard
    curl
  ] ++ lib.optionals (hyprland != null) [ hyprland ]
    ++ lib.optionals (ydotool != null) [ ydotool ];

  postInstall = ''
    # Install helper scripts
    install -Dm755 $src/chezwizper-toggle.sh $out/bin/chezwizper-toggle
    install -Dm755 $src/chezwizper-status.sh $out/bin/chezwizper-status
    
    # Create default config file
    mkdir -p $out/etc/chezwizper
    cat > $out/etc/chezwizper/config.toml << EOF
[audio]
device = "default"
sample_rate = 16000
channels = 1

[whisper]
model = "base"
language = "en"
command_path = "${whisper-cpp}/bin/whisper-cli"
# model_path = "~/.local/share/chezwizper/models/ggml-base.bin"

[ui]
indicator_position = "top-right"
indicator_size = 20
show_notifications = true
layer_shell_anchor = "top | right"
layer_shell_margin = 10

[wayland]
input_method = "wtype"
use_hyprland_ipc = true

[behavior]
auto_paste = true
preserve_clipboard = false
delete_audio_files = true
EOF
    
    # Create a "whisper" symlink to whisper-cli for compatibility
    # ChezWizper looks for "whisper" in PATH first
    ln -sf ${whisper-cpp}/bin/whisper-cli $out/bin/whisper
    
    # Create wrapper script that sets up config if needed
    cat > $out/bin/chezwizper-nix << 'EOF'
#!/bin/bash

# Default config location
CONFIG_DIR="$HOME/.config/chezwizper"
CONFIG_FILE="$CONFIG_DIR/config.toml"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Copy default config if none exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Creating default config at $CONFIG_FILE"
  cp "${placeholder "out"}/etc/chezwizper/config.toml" "$CONFIG_FILE"
  
  # Update model path in user config
  if [ -f "$HOME/.local/share/chezwizper/models/ggml-base.bin" ]; then
    sed -i 's|# model_path = .*|model_path = "'$HOME'/.local/share/chezwizper/models/ggml-base.bin"|' "$CONFIG_FILE"
  fi
fi

# Run the actual chezwizper binary
exec "${placeholder "out"}/bin/.chezwizper-wrapped" "$@"
EOF
    chmod +x $out/bin/chezwizper-nix
    
    # Replace original binary with our wrapper
    mv $out/bin/chezwizper $out/bin/.chezwizper-wrapped
    mv $out/bin/chezwizper-nix $out/bin/chezwizper
    
    # Wrap the binary to include runtime dependencies in PATH
    wrapProgram $out/bin/.chezwizper-wrapped \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}:$out/bin
  '';

  meta = with lib; {
    description = "Voice transcription tool for Wayland/Hyprland";
    homepage = "https://github.com/matsilva/whispy";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "chezwizper";
  };
}
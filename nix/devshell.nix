{ pkgs, ... }:

pkgs.mkShell {
  name = "chezwizper-dev";

  buildInputs = with pkgs; [
    # Rust toolchain
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Build dependencies
    pkg-config
    alsa-lib
    libxkbcommon

    # Runtime dependencies
    whisper-cpp
    openai-whisper
    wtype
    ydotool
    wl-clipboard
    curl
    hyprland

    # Development tools
    pre-commit
    cargo-watch
    cargo-edit
    cargo-outdated
    cargo-audit

    # Helper tools
    jq
    ripgrep
    fd
  ];

  shellHook = ''
    echo "ChezWizper Development Environment"
    echo "================================="
    echo ""
    echo "Available commands:"
    echo "  cargo build          - Build the project"
    echo "  cargo run            - Run ChezWizper"
    echo "  cargo test           - Run tests"
    echo "  cargo clippy         - Run linter"
    echo "  cargo fmt            - Format code"
    echo "  cargo watch -x run   - Run with auto-reload"
    echo ""
    echo "Whisper:"
    echo "  whisper-cpp and OpenAI whisper are available in PATH"
    echo "  Download models with: ./nix/download-models.sh"
    echo ""
    echo "Configuration:"
    echo "  Config location: ~/.config/chezwizper/config.toml"
    echo ""
    
    # Set up pre-commit hooks if not already done
    if [ ! -f .git/hooks/pre-commit ]; then
      pre-commit install
    fi
    
    # Create config directory if it doesn't exist
    mkdir -p ~/.config/chezwizper
    
    # Set Rust backtrace for better debugging
    export RUST_BACKTRACE=1
    export RUST_LOG=chezwizper=debug
    
    # Ensure we're using the right Rust source path
    export RUST_SRC_PATH="${pkgs.rustPlatform.rustLibSrc}"
  '';

  # Environment variables
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
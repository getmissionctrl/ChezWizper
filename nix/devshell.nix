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
    alsa-utils  # Provides aplay, speaker-test for audio feedback

    # Development tools
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
    echo "Make commands (see Makefile):"
    echo "  make build           - Build debug binary"
    echo "  make release         - Build optimized release"
    echo "  make test            - Run tests"
    echo "  make lint            - Run clippy linter"
    echo "  make fmt             - Check formatting"
    echo "  make fix             - Fix formatting and simple issues"
    echo ""
    echo "Whisper:"
    echo "  whisper-cpp available as 'whisper-cli'"
    echo "  Use 'whisper-cli --help' for usage information"
    echo ""
    
    
    
    # Set Rust backtrace for better debugging
    export RUST_BACKTRACE=1
    export RUST_LOG=chezwizper=debug
    
    # Ensure we're using the right Rust source path
    export RUST_SRC_PATH="${pkgs.rustPlatform.rustLibSrc}"
  '';

  # Environment variables
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
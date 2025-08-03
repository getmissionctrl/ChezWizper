{ lib
, rustPlatform
, pkg-config
, alsa-lib
, alsa-utils
, libxkbcommon
, whisper-cpp
, openai-whisper
, makeWrapper
# Runtime dependencies
, ydotool
, wtype
, wl-clipboard
, curl
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

  # Runtime dependencies that need to be available in PATH
  runtimeDeps = [
    whisper-cpp
    openai-whisper
    ydotool
    wtype
    wl-clipboard
    curl
    alsa-utils  # Provides aplay, speaker-test, etc.
  ];

  postInstall = ''
    # Wrap the binary to include all runtime dependencies in PATH
    wrapProgram $out/bin/chezwizper \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
    
    # Create a symlink for whisper compatibility (ChezWizper looks for 'whisper' command)
    ln -sf ${whisper-cpp}/bin/whisper-cli $out/bin/whisper
  '';

  meta = with lib; {
    description = "Voice transcription tool for Wayland/Hyprland";
    homepage = "https://github.com/silvabyte/ChezWizper";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "chezwizper";
  };
}
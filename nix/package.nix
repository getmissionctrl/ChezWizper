{ lib
, rustPlatform
, pkg-config
, alsa-lib
, libxkbcommon
, whisper-cpp
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

  postInstall = ''
    # Wrap the binary to include whisper-cpp in PATH
    wrapProgram $out/bin/chezwizper \
      --prefix PATH : ${lib.makeBinPath [ whisper-cpp ]}
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
{ lib
, stdenv
, fetchurl
, models ? [ "base" ] # Default to base model, can be overridden
}:

let
  # Model URLs and metadata
  modelInfo = {
    tiny = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin";
      sha256 = "sha256-hWPgSFk1q/oF8ooKnRyxRlOmL4qcj8BQ9RJNRrOHW7w=";
      size = "39M";
    };
    tiny-en = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin";
      sha256 = "sha256-W8HCwOMCMFjgEb4W4sZJQ7MbYnb4EQq3bWCNayEVyL4=";
      size = "39M";
    };
    base = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      sha256 = "sha256-MCYKXRh6ZXN6R1oeqqRKF6gm7SYlrzQcpCAtqefhZ9c=";
      size = "148M";
    };
    base-en = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
      sha256 = "sha256-JlG9EuxXN1x6yg+XoZhbZCJLdB4xqxTLq8zF0x1+0aM=";
      size = "148M";
    };
    small = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
      sha256 = "sha256-bZBKev92mOJpkjAVVKKpx1zxbhT5+3JrLvVdG6xJD/c=";
      size = "466M";
    };
    small-en = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin";
      sha256 = "sha256-KE6kd9cqMBQEYN+yVlCZ7zd3rZC8x1cqKE+zl1CJBn8=";
      size = "466M";
    };
    medium = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin";
      sha256 = "sha256-FUWKmmH6rlFFFX2NXRNpHc89p5LbF9A/+hzwGQ8NZvY=";
      size = "1.5G";
    };
    medium-en = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin";
      sha256 = "sha256-5bS9F2NV2R8F2Qy9b7kGb9E2YKM3pQ4VU+vUzHV8cQ0=";
      size = "1.5G";
    };
    large-v1 = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v1.bin";
      sha256 = "sha256-vnfgTLQx1R2QzGWh8+4C1HvLQV9X2vJrK9G6z8D2vk8=";
      size = "3.1G";
    };
    large-v2 = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin";
      sha256 = "sha256-K4qJ4V6C2YsG8GhM7L6NzRz8kFGf4+EuEzQQtY8+Pk4=";
      size = "3.1G";
    };
    large-v3 = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin";
      sha256 = "sha256-/HYGpTJ8hj8FTsG2GvL8n4tGM8q9P7kV3GgZ5YZ8J7c=";
      size = "3.1G";
    };
  };

  # Function to fetch a single model
  fetchModel = modelName:
    let
      info = modelInfo.${modelName} or (throw "Unknown model: ${modelName}. Available models: ${toString (builtins.attrNames modelInfo)}");
    in
    fetchurl {
      name = "ggml-${modelName}.bin";
      url = info.url;
      sha256 = info.sha256;
    };

  # Create a derivation that contains all requested models
  modelFiles = map fetchModel models;

in
stdenv.mkDerivation rec {
  pname = "whisper-models";
  version = "1.0";

  # Use a dummy source since we're just collecting files
  src = null;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/whisper-models
    ${lib.concatMapStringsSep "\n" (model: 
      let modelFile = fetchModel model; in
      "cp ${modelFile} $out/share/whisper-models/ggml-${model}.bin"
    ) models}
    
    # Create a simple index file
    cat > $out/share/whisper-models/README.txt << EOF
Whisper Models Package
=====================

This package contains the following whisper models:
${lib.concatMapStringsSep "\n" (model: "- ${model} (${modelInfo.${model}.size})") models}

Usage:
  whisper-cli -m \$out/share/whisper-models/ggml-MODEL.bin -f audio.wav

Available models in this package:
${lib.concatMapStringsSep "\n" (model: "  ggml-${model}.bin") models}
EOF
  '';

  meta = with lib; {
    description = "Pre-downloaded Whisper models for offline speech recognition";
    longDescription = ''
      This package contains pre-downloaded Whisper models for use with whisper.cpp.
      Models included: ${toString models}
      
      The models are stored in \$out/share/whisper-models/ and can be used with
      ChezWizper or whisper-cli directly.
    '';
    homepage = "https://github.com/ggerganov/whisper.cpp";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
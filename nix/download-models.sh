#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
MODEL_DIR="${HOME}/.local/share/chezwizper/models"
BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

# Available models
declare -A MODELS=(
    ["tiny"]="ggml-tiny.bin"
    ["tiny.en"]="ggml-tiny.en.bin"
    ["base"]="ggml-base.bin"
    ["base.en"]="ggml-base.en.bin"
    ["small"]="ggml-small.bin"
    ["small.en"]="ggml-small.en.bin"
    ["medium"]="ggml-medium.bin"
    ["medium.en"]="ggml-medium.en.bin"
    ["large-v1"]="ggml-large-v1.bin"
    ["large-v2"]="ggml-large-v2.bin"
    ["large-v3"]="ggml-large-v3.bin"
    ["large-v3-turbo"]="ggml-large-v3-turbo.bin"
)

# Model sizes (approximate)
declare -A MODEL_SIZES=(
    ["tiny"]="39 MB"
    ["tiny.en"]="39 MB"
    ["base"]="74 MB"
    ["base.en"]="74 MB"
    ["small"]="244 MB"
    ["small.en"]="244 MB"
    ["medium"]="769 MB"
    ["medium.en"]="769 MB"
    ["large-v1"]="1550 MB"
    ["large-v2"]="1550 MB"
    ["large-v3"]="1550 MB"
    ["large-v3-turbo"]="809 MB"
)

print_usage() {
    echo "Usage: $0 [OPTIONS] [MODEL]"
    echo ""
    echo "Download Whisper models for use with ChezWizper"
    echo ""
    echo "Models:"
    echo "  tiny          - Tiny model (39 MB)"
    echo "  tiny.en       - Tiny model, English only (39 MB)"
    echo "  base          - Base model (74 MB) [recommended for testing]"
    echo "  base.en       - Base model, English only (74 MB)"
    echo "  small         - Small model (244 MB)"
    echo "  small.en      - Small model, English only (244 MB)"
    echo "  medium        - Medium model (769 MB)"
    echo "  medium.en     - Medium model, English only (769 MB)"
    echo "  large-v1      - Large model v1 (1550 MB)"
    echo "  large-v2      - Large model v2 (1550 MB)"
    echo "  large-v3      - Large model v3 (1550 MB)"
    echo "  large-v3-turbo - Large model v3 turbo (809 MB) [recommended for quality]"
    echo ""
    echo "Options:"
    echo "  -d, --dir DIR    Model directory (default: ~/.local/share/chezwizper/models)"
    echo "  -l, --list       List available models"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 base                    # Download base model"
    echo "  $0 -d /opt/models large-v3-turbo  # Download large-v3-turbo to /opt/models"
}

list_models() {
    echo "Available models:"
    echo ""
    printf "%-15s %-25s %s\n" "Model" "Filename" "Size"
    printf "%-15s %-25s %s\n" "-----" "--------" "----"
    for model in "${!MODELS[@]}"; do
        printf "%-15s %-25s %s\n" "$model" "${MODELS[$model]}" "${MODEL_SIZES[$model]}"
    done | sort
}

download_model() {
    local model=$1
    local filename="${MODELS[$model]}"
    local url="${BASE_URL}/${filename}"
    local output_path="${MODEL_DIR}/${filename}"
    
    echo -e "${GREEN}Downloading model:${NC} $model (${MODEL_SIZES[$model]})"
    echo -e "${GREEN}From:${NC} $url"
    echo -e "${GREEN}To:${NC} $output_path"
    echo ""
    
    # Create directory if it doesn't exist
    mkdir -p "$MODEL_DIR"
    
    # Download with progress bar
    if command -v wget >/dev/null 2>&1; then
        wget --show-progress -O "$output_path" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar -o "$output_path" "$url"
    else
        echo -e "${RED}Error: Neither wget nor curl found. Please install one of them.${NC}"
        exit 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Successfully downloaded:${NC} $output_path"
        echo ""
        echo "To use this model, add to your ChezWizper config:"
        echo ""
        echo "[whisper]"
        echo "model = \"$model\""
        echo "model_path = \"$output_path\""
    else
        echo -e "\n${RED}Error downloading model${NC}"
        rm -f "$output_path"
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            MODEL_DIR="$2"
            shift 2
            ;;
        -l|--list)
            list_models
            exit 0
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            MODEL="$1"
            shift
            ;;
    esac
done

# Check if model was specified
if [ -z "${MODEL:-}" ]; then
    echo -e "${RED}Error: No model specified${NC}"
    echo ""
    print_usage
    exit 1
fi

# Check if model exists
if [ -z "${MODELS[$MODEL]:-}" ]; then
    echo -e "${RED}Error: Unknown model '$MODEL'${NC}"
    echo ""
    list_models
    exit 1
fi

# Download the model
download_model "$MODEL"
#!/usr/bin/env nix-shell
#!nix-shell -i bash --pure
#! nix-shell -p python312 python312Packages.huggingface-hub
export HF_HUB_ENABLE_HF_TRANSFER=1
MODELS_DIR="models"
BASE_MODEL="parler-tts-mini-v1"

mkdir "${MODELS_DIR}"
huggingface-cli download "ecyht2/${BASE_MODEL}-GGUF" "${BASE_MODEL}-fp32.gguf" --local-dir="${MODELS_DIR}"
for qt in $(cat qt.txt)
do
    QT=$(echo $qt | cut -d "," -f 2)
    QT_NAME=$(echo $qt | cut -d "," -f 1)
    ./quantize -mp "${MODELS_DIR}/${BASE_MODEL}-fp32.gguf" -qp "${MODELS_DIR}/${BASE_MODEL}-${QT_NAME}.gguf" -qt "${QT}"
done
huggingface-cli upload --exclude="${BASE_MODEL}-fp32.gguf" "ecyht2/${BASE_MODEL}-GGUF" "${MODELS_DIR}"

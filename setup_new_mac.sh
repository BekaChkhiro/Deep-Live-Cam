#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# FaceSwap (Deep-Live-Cam) — one-shot setup for a FRESH Apple Silicon Mac.
# Installs: Xcode CLT, Homebrew, Python 3.11, ffmpeg, OBS, all Python deps,
# and downloads the face-swap models. Safe to re-run.
# Usage:  bash setup_new_mac.sh
# ---------------------------------------------------------------------------
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

echo "==> FaceSwap setup starting in: $HERE"

# 0. Must be Apple Silicon (onnxruntime-silicon is arm64-only).
if [ "$(uname -m)" != "arm64" ]; then
  echo "!! This setup targets Apple Silicon (M1/M2/M3/M4). Detected: $(uname -m)"
  echo "   Stopping. Ask for an Intel-specific setup if you need it."
  exit 1
fi

# 1. Xcode Command Line Tools (needed by Homebrew / pip builds).
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools — click 'Install' in the dialog…"
  xcode-select --install || true
  echo "    Waiting for Command Line Tools to finish (this can take 5-10 min)…"
  while ! xcode-select -p >/dev/null 2>&1; do
    printf '.'          # heartbeat, so a long install never looks frozen
    sleep 10
  done
  echo " done."
fi

# 2. Homebrew.
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. System packages + OBS (OBS provides the virtual-camera system extension).
echo "==> Installing python@3.11, ffmpeg, OBS…"
brew install python@3.11 ffmpeg
brew install --cask obs || echo "   (OBS may already be installed — continuing)"

PYTHON="$(brew --prefix)/opt/python@3.11/bin/python3.11"

# 4. Python virtual environment + dependencies.
echo "==> Creating Python 3.11 virtual environment…"
[ -d venv ] && rm -rf venv
"$PYTHON" -m venv venv
./venv/bin/python -m pip install --upgrade pip wheel setuptools
echo "==> Installing Python dependencies (5-15 min, quiet stretches are normal)…"
./venv/bin/python -m pip install -r requirements.txt

# 5. Face-swap models.
mkdir -p models
if [ ! -f models/inswapper_128_fp16.onnx ]; then
  echo "==> Downloading inswapper_128_fp16.onnx (~277 MB)…"
  curl -L -o models/inswapper_128_fp16.onnx \
    "https://huggingface.co/hacksider/deep-live-cam/resolve/main/inswapper_128_fp16.onnx?download=true"
fi
if [ ! -f models/GFPGANv1.4.onnx ]; then
  echo "==> Downloading GFPGANv1.4.onnx (~340 MB)…"
  curl -L -o models/GFPGANv1.4.onnx \
    "https://huggingface.co/hacksider/deep-live-cam/resolve/main/GFPGANv1.4.onnx?download=true"
fi

echo ""
echo "============================================================"
echo " ✅ Setup complete."
echo ""
echo " ONE-TIME virtual-camera approval (required by macOS):"
echo "   1. Open OBS, click 'Start Virtual Camera' (bottom-right)."
echo "   2. System Settings → General → Login Items & Extensions →"
echo "      Camera Extensions → enable 'OBS Virtual Camera'."
echo "   3. Quit OBS. You never need to open it again."
echo ""
echo " To run the app: double-click 'Start FaceSwap.command'"
echo "   then: Select a face → Live → pick 'OBS Virtual Camera' in Meet."
echo "============================================================"

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# FaceSwap (Deep-Live-Cam) — ONE-COMMAND installer for a fresh Apple Silicon Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/BekaChkhiro/Deep-Live-Cam/main/install.sh | bash
#
# Downloads this repo, then runs setup_new_mac.sh (Xcode CLT, Homebrew,
# Python 3.11, ffmpeg, OBS, all Python deps, and the face-swap models).
# Needs no git, no GitHub account and no Homebrew on the target machine.
# Safe to re-run: it refreshes the code and keeps venv/ and models/.
#
# Override the defaults with env vars, e.g.:
#   INSTALL_DIR=~/Apps/FaceSwap curl -fsSL <url> | bash
# ---------------------------------------------------------------------------
set -euo pipefail

REPO="${REPO:-BekaChkhiro/Deep-Live-Cam}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Developer/Deep-Live-Cam}"

# When run through `curl | bash`, stdin is the script itself. Re-point it at the
# terminal so anything downstream (sudo password, brew) can still ask the user.
if [ ! -t 0 ] && [ -r /dev/tty ]; then exec </dev/tty; fi

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$1" >&2; exit 1; }

say "FaceSwap installer — $REPO ($BRANCH)"

# 1. Apple Silicon only (onnxruntime-silicon / CoreML are arm64-only).
if [ "$(uname -s)" != "Darwin" ]; then
  die "This installer is for macOS. Detected: $(uname -s)"
fi
if [ "$(uname -m)" != "arm64" ]; then
  die "This installer targets Apple Silicon (M1/M2/M3/M4). Detected: $(uname -m)"
fi

# 2. Fetch the source as a tarball — avoids needing git on a fresh machine.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
say "Downloading source…"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
  -o "$TMP/src.tar.gz" || die "Download failed. Check your internet connection."
tar -xzf "$TMP/src.tar.gz" -C "$TMP"
SRC="$(find "$TMP" -maxdepth 1 -type d -name '*-*' | head -1)"
[ -f "$SRC/run.py" ] || die "Downloaded archive looks wrong (no run.py)."

# 3. Copy into place, preserving an existing venv/ and models/ on re-runs.
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/run.py" ]; then
  say "Existing install found — refreshing code, keeping venv/ and models/"
elif [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
  die "$INSTALL_DIR exists and is not a FaceSwap install. Move it, or re-run with INSTALL_DIR=<other path>."
else
  say "Installing into: $INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
/usr/bin/rsync -a --exclude 'venv/' --exclude 'models/' "$SRC"/ "$INSTALL_DIR"/
chmod +x "$INSTALL_DIR/setup_new_mac.sh" "$INSTALL_DIR/Start FaceSwap.command" 2>/dev/null || true

# 4. Hand over to the real setup (deps + models). It is idempotent.
say "Running setup — this installs Homebrew, Python 3.11, ffmpeg, OBS and the"
echo "    Python dependencies. It takes 10–20 minutes and may ask for your"
echo "    Mac password (that is macOS, not this script)."
cd "$INSTALL_DIR"
bash setup_new_mac.sh

# 5. Make it double-clickable from the Desktop.
ln -sfn "$INSTALL_DIR/Start FaceSwap.command" "$HOME/Desktop/Start FaceSwap.command" 2>/dev/null || true

printf '\n\033[1;32m✅ Installed at: %s\033[0m\n' "$INSTALL_DIR"
echo "   A 'Start FaceSwap' shortcut was placed on your Desktop."

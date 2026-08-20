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
#
# NOTE: never `exec < ...` anywhere in this file. When the script is piped into
# bash it *is* stdin, so redirecting it discards every line not yet read and the
# install silently stops. Redirect per-command instead (see step 4).
# ---------------------------------------------------------------------------
set -euo pipefail

REPO="${REPO:-BekaChkhiro/Deep-Live-Cam}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Developer/Deep-Live-Cam}"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\n\033[1;31m!! %s\033[0m\n' "$1" >&2; exit 1; }

say "FaceSwap installer — $REPO ($BRANCH)"
echo "    Target: $INSTALL_DIR"

# 1. Apple Silicon only (onnxruntime-silicon / CoreML are arm64-only).
say "[1/4] Checking this Mac…"
[ "$(uname -s)" = "Darwin" ] || die "This installer is for macOS. Detected: $(uname -s)"
[ "$(uname -m)" = "arm64" ]  || die "This installer targets Apple Silicon (M1/M2/M3/M4). Detected: $(uname -m)"
echo "    OK — $(sw_vers -productName) $(sw_vers -productVersion), $(uname -m)"

# 2. Fetch the source as a tarball — avoids needing git on a fresh machine.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
say "[2/4] Downloading source (~64 MB) — progress below:"
curl -fL --progress-bar "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
  -o "$TMP/src.tar.gz" || die "Download failed. Check your internet connection."
echo "    Extracting…"
tar -xzf "$TMP/src.tar.gz" -C "$TMP"
SRC="$(find "$TMP" -maxdepth 1 -type d -name '*-*' | head -1)"
[ -n "$SRC" ] && [ -f "$SRC/run.py" ] || die "Downloaded archive looks wrong (no run.py)."

# 3. Copy into place, preserving an existing venv/ and models/ on re-runs.
say "[3/4] Installing files…"
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/run.py" ]; then
  echo "    Existing install found — refreshing code, keeping venv/ and models/"
elif [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
  die "$INSTALL_DIR exists and is not a FaceSwap install. Move it, or re-run with INSTALL_DIR=<other path>."
fi
mkdir -p "$INSTALL_DIR"
/usr/bin/rsync -a --exclude 'venv/' --exclude 'models/' "$SRC"/ "$INSTALL_DIR"/
chmod +x "$INSTALL_DIR/setup_new_mac.sh" "$INSTALL_DIR/Start FaceSwap.command" 2>/dev/null || true
echo "    Done."

# 4. Hand over to the real setup (deps + models). It is idempotent.
say "[4/4] Running setup — Homebrew, Python 3.11, ffmpeg, OBS, deps, models."
echo "    This takes 10–20 minutes. Long quiet stretches during pip installs"
echo "    are normal. macOS may ask for your Mac password — that is macOS,"
echo "    not this script."
cd "$INSTALL_DIR"
# Per-command redirect (NOT exec) so brew/sudo can prompt without eating this
# script's own stdin when it is being piped in from curl.
if [ -r /dev/tty ]; then
  bash setup_new_mac.sh < /dev/tty
else
  bash setup_new_mac.sh
fi

# 5. Make it double-clickable from the Desktop (a wrapper, not a symlink, so
#    the launcher always resolves the real install directory).
SHORTCUT="$HOME/Desktop/Start FaceSwap.command"
{
  printf '#!/usr/bin/env bash\n'
  printf 'exec %s\n' "$(printf '%q' "$INSTALL_DIR/Start FaceSwap.command")"
} > "$SHORTCUT" && chmod +x "$SHORTCUT"

printf '\n\033[1;32m✅ Installed at: %s\033[0m\n' "$INSTALL_DIR"
echo "   A 'Start FaceSwap' shortcut was placed on your Desktop."

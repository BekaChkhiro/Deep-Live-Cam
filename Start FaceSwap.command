#!/usr/bin/env bash
# Double-click to launch the face swap (CoreML accelerated, mirrored preview).
# Resolve symlinks so this still works when launched via a Desktop shortcut.
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
  DIR="$(cd -P "$(dirname "$SELF")" && pwd)"
  SELF="$(readlink "$SELF")"
  case "$SELF" in /*) ;; *) SELF="$DIR/$SELF" ;; esac
done
cd "$(cd -P "$(dirname "$SELF")" && pwd)"
exec ./venv/bin/python run.py --execution-provider coreml --live-mirror

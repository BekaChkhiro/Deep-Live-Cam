#!/usr/bin/env bash
# Double-click to launch the face swap (CoreML accelerated, mirrored preview).
cd "$(dirname "$0")"
exec ./venv/bin/python run.py --execution-provider coreml --live-mirror

#!/bin/bash
# Builds the debug APK after running the automated tests.
# Usage: tools/build_apk.sh        (needs the "godot" command, see docs/BUILD.md)
set -e
cd "$(dirname "$0")/.."
mkdir -p build
godot --headless --path . --import
tools/run_tests.sh
godot --headless --path . --export-debug "Android" build/the-missing-file-debug.apk
ls -la build/*.apk

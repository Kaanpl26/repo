#!/bin/bash
# Runs the automated tests. Fails if any check fails or if the tests could not start.
cd "$(dirname "$0")/.."
out=$(godot --headless --path . --quit-after 3000 res://tests/run_tests.tscn 2>&1)
echo "$out" | grep -E "^- |FAIL|SCRIPT ERROR|Parse Error|checks,"
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then echo "SCRIPT ERRORS FOUND"; exit 1; fi
echo "$out" | grep -qE "[0-9]+ checks, 0 failed" || { echo "TESTS DID NOT PASS"; exit 1; }

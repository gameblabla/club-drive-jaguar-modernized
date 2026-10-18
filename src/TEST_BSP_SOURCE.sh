#!/usr/bin/env bash
# Reconstructed collision BSP source tests (2026). No emulator needed here.
set -euo pipefail
cd "$(dirname "$0")"
python3 tests/test_bsp.py
python3 build/bsp_authoring.py check
python3 build/native_model_pipeline.py check
python3 build/collision_audit.py
printf 'bsp BSP and source-geometry checks passed.\n'

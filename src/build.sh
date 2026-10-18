#!/usr/bin/env bash
# Club Drive cartridge builder.
# The complete build sequence lives here; assets are read directly from src/assets.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

stage_original_resources() (
  set -euo pipefail
# resources: build authenticated Jaguar hybrid AND independently reconstruct/link
# executable resource providers and editable 3D model sources. The source-link
# intermediate is not runnable, even though the hybrid .j64 is tested.
if [[ $# -lt 2 ]];then
  echo 'Usage: build.sh retail.zip sdk_dir [rom_output.j64]' >&2
  exit 2
fi
REF="$(realpath "$1")"
SDK="$(realpath "$2")"
cd "$(dirname "$0")"
OUTPUT="${3:-Club_Drive_reconstructed.j64}"
python3 build/recover_graphics_assets.py "$REF"
python3 build/recover_binary_helpers.py "$REF"
python3 build/recover_tail_resources.py "$REF"
python3 build/compile_tail_graphics.py export
WORLD_EDIT_FLAGS=()
if [[ "${CLUB_ALLOW_EDITED_WORLD_GPU:-0}" == "1" ]]; then WORLD_EDIT_FLAGS+=(--allow-edited-world-gpu); fi
python3 build_reconstructed.py --reference "$REF" --sdk "$SDK" --output "$OUTPUT" "${WORLD_EDIT_FLAGS[@]}"
python3 build/generate_legacy_equates.py
"$SDK/tools/bin/rmac" -fb -u -o build/obj/legacy_equates_recovered.o LEGACY_EQUATES_RECOVERED.S
python3 build/normalize_fulsyn_symbols.py
python3 build/link_recovered_stage.py --sdk "$SDK" --reference "$REF" --extract "${WORLD_EDIT_FLAGS[@]}"
python3 build/convert_asc.py --verify
python3 build/match_remaining_gpu.py "$REF"
python3 build/check_reconstruction.py --reference "$REF" --rebuilt "$OUTPUT" --sdk "$SDK"
echo 'resources: authenticated hybrid ROM built, legacy equates linked, geometry recovered.'
echo 'Important: build/source_link_stage5.abs is NOT a bootable source-linked cartridge.'
)


stage_source() (
  set -euo pipefail
# AUDIO_PORTABLE metadata-free WAV/MIDI must reconstruct original native audio byte-for-byte.
# For edited sources use the separate patch-rom command, not the retail wrapper.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail.zip jaguar-sdk-directory [headless-emulator] [out.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 build/audio_portable.py check
python3 tests/test_audio_portable.py > build/audio_portable_prebuild_tests.log 2>&1
stage_audio_native "$@"
python3 build/audio_portable.py check
python3 tests/test_audio_portable.py > build/audio_portable_postbuild_tests.log 2>&1
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
import sys,hashlib
from pathlib import Path
from zipfile import ZipFile
with ZipFile(sys.argv[1]) as z:
    members=[n for n in z.namelist() if n.lower().endswith(('.j64','.rom'))]
    if len(members)!=1:raise SystemExit('Retail reference selection not unique')
    retail=z.read(members[0])
rebuilt=Path(sys.argv[2]).read_bytes()
if len(rebuilt)!=2097152 or rebuilt!=retail:raise SystemExit('AUDIO_PORTABLE ROM differs from retail reference')
print('AUDIO_PORTABLE_COMPLETE_SOURCE_ROM',len(rebuilt),hashlib.sha256(rebuilt).hexdigest())
PY
)


stage_artwork() (
  set -euo pipefail
# CLUB DRIVE reconstruction (2026) — PNG-authoritative artwork edition.
# The original Jaguar source comments are preserved in ART_ORIGINAL_1994.S.
# PNG compiler writes byte-perfect ART.S INCBIN inputs before the source link.
# For compressed world formats still unknown, original decoded binary sources
# remain authoritative; no claim is made that the old TGA compiler survives.
if [[ $# -lt 2 ]]; then
    echo 'Usage: stage_artwork retail-reference.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
    exit 2
fi
cd "$(dirname "$0")"
python3 build/png_art_pipeline.py compile
stage_audio_bank "$1" "$2" "${3:-/bin/true}" "${4:-Club_Drive.j64}"
)


stage_asc_authoring() (
  set -euo pipefail
# Club Drive (2026 reconstruction), ASC-authoring bridge for Jaguar car models.
# Preserve the original Atari assembly comments and source control structure.
cd "$(dirname "$0")"
python3 build/asc_authoring.py compile
python3 build/render_asc.py
python3 build/native_model_pipeline.py check
python3 build/collision_audit.py
# Only the three linked ASC car models affect Jaguar geometry. If any edit
# reaches a runtime *.mdl include, re-link the CPU; PNG-only fast builds must
# not silently omit geometry modifications.
if python3 build/asc_has_runtime_edits.py; then
  export CLUB_ALLOW_NATIVE_MODEL_EDITS=1
fi
stage_models "$@"
)


stage_audio_bank() (
  set -euo pipefail
# ---------------------------------------------------------------------------
# CLUB DRIVE: historical-layout reconstruction with editable packed resources
# ---------------------------------------------------------------------------
# RECONSTRUCTION NOTE (2026; not a surviving Atari build script):
# Run the preserved source-link pipeline, then regenerate all 22 gzip inputs
# from their verified decoded source files. Unchanged inputs preserve their
# *original* compressed bitstreams. Resource edits must fit their old slots.
# This stage never imports the retail data bank wholesale.
if [[ $# -lt 2 ]]; then
    echo 'Usage: build.sh retail-reference.zip sdk-dir [emulator] [output.j64]' >&2
    exit 2
fi
REF="$(realpath "$1")"
SDK="$(realpath "$2")"
EMU="$(realpath "${3:-/bin/true}")"
cd "$(dirname "$0")"
OUT="${4:-Club_Drive.j64}"
# Keep the original 26 CPU and 21 GPU source builds, linker placements,
# authenticated header template, relocation verification and comments.
if [[ "${CLUB_ALLOW_RETAIL_BANK_EDITS:-0}" == 1 ]]; then
    # Incremental asset edits must NOT shift modern RLN data addresses;
    # the retail slot packer works from the last clean-linked executable.
    # A separate clean build is required to incorporate CPU code changes.
    python3 build/assemble_asset_sources.py --sdk "$SDK"
else
    CLUB_BUILD_RETAIL_SLOT=0 CLUB_RUN_EMULATOR_TEST=0 stage_retail_link \
        "$REF" "$SDK" "$EMU" Club_Drive_source_integrated.j64
fi
ARGS=(--source Club_Drive_source_integrated.j64 --sdk "$SDK" --reference "$REF" --output "$OUT")
if [[ "${CLUB_ALLOW_RETAIL_BANK_EDITS:-0}" == 1 ]]; then
    ARGS+=(--allow-edited-resources)
fi
python3 build/rebuild_original_bank.py "${ARGS[@]}" --manifest build/audio_bank_bank_index.json
if [[ "${CLUB_RUN_EMULATOR_TEST:-0}" == 1 ]]; then
    python3 build/validate_source_retail.py --reference "$REF" --source "$OUT" \
        --emulator "$EMU" --frames "${CLUB_TEST_FIELDS:-600}" \
        --interval "${CLUB_TEST_INTERVAL:-300}" --timeout "${CLUB_TEST_TIMEOUT:-120}"
fi
printf 'audio_bank source + decoded-resource cartridge build completed: %s\n' "$OUT"
sha256sum "$OUT"
)


stage_audio_native() (
  set -euo pipefail
# Audio source WAV/MIDI now authoritative for 49 native audio resources.
# Unmodified intermediate assets must rebuild an identical retail cartridge.
if [[ $# -lt 2 ]]; then
 echo 'Usage: build.sh retail.zip jaguar-sdk-directory [headless-emulator] [out.j64]' >&2
 exit 2
fi
cd "$(dirname "$0")"
python3 build/audio_roundtrip.py compile --sync-recovered
python3 tests/test_audio_roundtrip.py > build/audio_native_audio_prebuild_tests.log 2>&1
stage_contact_events "$@"
python3 tests/test_audio_roundtrip.py > build/audio_native_audio_postbuild_tests.log 2>&1
python3 build/audio_roundtrip.py compile
python3 - "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
import hashlib,sys
p=Path(sys.argv[1]);r=p.read_bytes()
print('AUDIO_NATIVE_COMPLETE_SOURCE_ROM',len(r),hashlib.sha256(r).hexdigest())
PY
)


stage_bnd_source() (
  set -euo pipefail
# bnd: edit/verify CARS/*.BND intermediates in authoring-only outputs.
# The game still links the original native .MDL files; never auto-inject BND edits.
if [[ $# -lt 2 ]]; then
  echo 'Usage: stage_bnd_source retail.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 tests/test_native_bnd.py > build/bnd_bnd_tests.log 2>&1
python3 build/native_bnd.py compile > build/bnd_bnd_compile.log
python3 build/native_bnd.py check > build/bnd_bnd_check.log
python3 build/native_bnd.py probe > build/bnd_bnd_probe.log
python3 build/audit_bnd_mdl.py > build/bnd_bnd_mdl_audit.log
python3 build/assemble_native_bnd.py --rmac "$2/tools/bin/rmac" > build/bnd_bnd_assembler.log
stage_geometry_tables "$@"
python3 build/native_bnd.py check > build/bnd_postbuild_bnd_check.log
python3 build/audit_bnd_mdl.py > build/bnd_postbuild_bnd_mdl_audit.log
python3 tests/test_native_bnd.py > build/bnd_postbuild_bnd_tests.log 2>&1
)


stage_bsp_authoring() (
  set -euo pipefail
# Club Drive (2026 reconstruction): editable native BSP JSON source bridge.
# Retain all Atari original .MDL comments and the asc PNG artwork pipeline.
# Safety: only same-size, validated existing BSP node geometry is supported;
# this build does NOT claim to regenerate partitions from arbitrary meshes.
cd "$(dirname "$0")"
python3 build/bsp_authoring.py stats
# asc performs a native-model preflight *before* its normal source link.
# Make sure its generated files already include bsp's BSP edits.
python3 build/native_model_pipeline.py compile > /dev/null
if python3 build/bsp_runtime_edit_check.py; then
  export CLUB_ALLOW_NATIVE_MODEL_EDITS=1
fi
# asc calls the native model compiler; that compiler now overlays validated
# BSP JSON *after* vertex/edge generation and before the Jaguar source link.
stage_asc_authoring "$@"
# Test the generated model and its lower-case play.s aliases after linking.
python3 build/native_model_pipeline.py check
python3 build/bsp_authoring.py check
)


stage_car2_model() (
  set -euo pipefail
if [[ $# -lt 2 ]]; then echo 'Usage: build.sh retail.zip sdk-dir [emulator] [output]' >&2; exit 2; fi
cd "$(dirname "$0")"
python3 tests/test_native_bnd_bridge.py > build/car2_bridge_tests.log 2>&1
python3 build/native_bnd.py probe > build/car2_source_bnd_probe.log
python3 build/native_bnd_to_mdl.py baseline > build/car2_bridge_baseline.log
python3 build/native_bnd_to_mdl.py probe > build/car2_bridge_probe.log
python3 build/native_bnd_to_mdl.py check > build/car2_bridge_check.log
python3 build/audit_bnd_to_mdl.py compile > build/car2_lineage.log
python3 build/audit_bnd_to_mdl.py check > build/car2_lineage_check.log
python3 build/assemble_bnd_bridge.py --rmac "$2/tools/bin/rmac" > build/car2_rmac.log
stage_bnd_source "$@"
python3 tests/test_native_bnd_bridge.py > build/car2_postbuild_tests.log 2>&1
python3 build/native_bnd_to_mdl.py check > build/car2_postbuild_check.log
python3 build/audit_bnd_to_mdl.py check > build/car2_postbuild_lineage_check.log
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import sys,hashlib
retail=Path(sys.argv[1]);new=Path(sys.argv[2]);
with ZipFile(retail) as z:
    names=[x for x in z.namelist() if x.lower().endswith(('.j64','.rom'))]
    if len(names)!=1:raise SystemExit('Original retail ZIP is ambiguous: '+str(names))
    baseline=z.read(names[0])
built=new.read_bytes()
if len(baseline)!=2097152 or built!=baseline:raise SystemExit('Retail byte equality failed')
print('CLEAN_ROM',len(built),hashlib.sha256(built).hexdigest())
PY
)


stage_car3_model() (
  set -euo pipefail
# Car3 authoring experiments are isolated; only original Atari native models
# remain in the retail-compatible ROM build inputs.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 build/native_car3_bridge.py baseline > build/car3_car3_baseline.log
python3 build/native_car3_bridge.py probe > build/car3_car3_probe.log
python3 build/native_car3_bridge.py check > build/car3_car3_check.log
python3 build/audit_native_traversal.py compile > build/car3_traversal.log
python3 build/audit_native_traversal.py check > build/car3_traversal_check.log
python3 tests/test_native_car3_bridge.py > build/car3_car3_tests.log 2>&1
python3 build/assemble_car3_bridge.py --rmac "$2/tools/bin/rmac" > build/car3_rmac.log
stage_car2_model "$@"
python3 build/native_car3_bridge.py check > build/car3_postbuild_car3_check.log
python3 build/audit_native_traversal.py check > build/car3_postbuild_traversal_check.log
python3 tests/test_native_car3_bridge.py > build/car3_postbuild_car3_tests.log 2>&1
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import hashlib,sys
with ZipFile(sys.argv[1]) as z:
    names=[x for x in z.namelist() if x.lower().endswith(('.j64','.rom'))]
    if len(names)!=1:raise SystemExit('Ambiguous retail input')
    retail=z.read(names[0])
product=Path(sys.argv[2]).read_bytes()
if len(product)!=2097152 or product!=retail:
    raise SystemExit('car3 clean build is not retail-identical')
print('CLEAN_ROM',len(product),hashlib.sha256(product).hexdigest())
PY
)


stage_collision_polygons() (
  set -euo pipefail
# polygons: Experimental original-vertex CP face compiler. Never links its alternate
# collision model into the clean retail ROM. All predecessor tests still run.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail-reference.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 tests/test_native_collision.py > build/polygons_native_collision_tests.log 2>&1
python3 build/native_collision.py compile > build/polygons_native_compile.log
python3 build/native_collision.py check > build/polygons_native_check.log
python3 build/native_collision.py probe > build/polygons_polygon_probe.log
if [[ -x "$2/tools/bin/rmac" ]]; then
  python3 build/assemble_native_collision.py --rmac "$2/tools/bin/rmac" > build/polygons_assembler_probe.log
else
  echo 'polygons RMAC model-assembly proof skipped; SDK rmac unavailable' > build/polygons_assembler_probe.log
fi
stage_native_tree "$@"
python3 build/native_collision.py check > build/polygons_postbuild_check.log
python3 tests/test_native_collision.py > build/polygons_postbuild_tests.log 2>&1
)


stage_contact_audit() (
  set -euo pipefail
# Recovered collision-contact evidence/preview is authoring-only.
# All original runtime game models are preserved in the clean build.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail.zip sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 build/audit_runtime_contact.py compile > build/contact_audit_contact_compile.log
python3 build/audit_runtime_contact.py check > build/contact_audit_contact_check.log
python3 tests/test_runtime_contact.py > build/contact_audit_contact_tests.log 2>&1
stage_car3_model "$@"
python3 build/audit_runtime_contact.py check > build/contact_audit_postbuild_contact_check.log
python3 tests/test_runtime_contact.py > build/contact_audit_postbuild_contact_tests.log 2>&1
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import hashlib,sys
with ZipFile(sys.argv[1]) as z:
    names=[x for x in z.namelist() if x.lower().endswith(('.j64','.rom'))]
    if len(names)!=1:raise SystemExit('Ambiguous retail ROM reference')
    retail=z.read(names[0])
result=Path(sys.argv[2]).read_bytes()
if len(result)!=2097152 or result!=retail:
    raise SystemExit('contact_audit clean cartridge differs from supplied retail reference')
print('CLEAN_ROM',len(result),hashlib.sha256(result).hexdigest())
PY
)


stage_contact_events() (
  set -euo pipefail
# CONTACT_EVENTS instrumentation changes emulator only; the game remains retail-identical.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail.zip sdk-directory [headless-emulator] [out.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 build/verify_collision_events.py check
python3 tests/test_collision_events.py > build/contact_events_prebuild_tests.log 2>&1
stage_gpu_trace "$@"
python3 build/verify_collision_events.py check
python3 tests/test_collision_events.py > build/contact_events_postbuild_tests.log 2>&1
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import hashlib, sys
with ZipFile(sys.argv[1]) as z:
    names=[n for n in z.namelist() if n.lower().endswith(('.j64','.rom'))]
    if len(names)!=1:raise SystemExit('Ambiguous retail reference')
    original=z.read(names[0])
out=Path(sys.argv[2]).read_bytes()
if len(out)!=2097152 or out!=original:raise SystemExit('CONTACT_EVENTS source ROM is not retail-identical')
print('CONTACT_EVENTS_CLEAN_ROM',len(out),hashlib.sha256(out).hexdigest())
PY
)


stage_geometry_partitions() (
  set -euo pipefail
# Club Drive (2026 reconstruction): original .ASC -> geometry-derived BSP.
# The generated authoring BSPs are independently validated planning data,
# NOT the Jaguar's native .MDL/.BND collision records. Gameplay continues to
# use the verified bsp native BSP serializer until compatible native writing
# and physical collision behavior can be independently established.
# All image outputs remain PNG. Original Atari source comments are preserved.
cd "$(dirname "$0")"
python3 tests/test_geometry_bsp.py > build/bsp_geometry_geometry_tests.log 2>&1
python3 build/geometry_bsp.py compile > build/bsp_geometry_geometry_compile.log
stage_bsp_authoring "$@"
python3 build/geometry_bsp.py check > build/bsp_geometry_geometry_check.log
)


stage_geometry_tables() (
  set -euo pipefail
# geometry: Full native collision geometry/plane/CP authoring remains unlinked.
# All predecessor polygons/native_tree/bsp_geometry and clean-ROM checks must still pass.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail-reference.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 tests/test_native_geometry.py > build/geometry_geometry_tests.log 2>&1
python3 build/native_geometry.py compile > build/geometry_geometry_compile.log
python3 build/native_geometry.py check > build/geometry_geometry_check.log
python3 build/native_geometry.py probe > build/geometry_geometry_probe.log
if [[ -x "$2/tools/bin/rmac" ]]; then
  python3 build/assemble_native_geometry.py --rmac "$2/tools/bin/rmac" > build/geometry_assembler_probe.log
else
  echo 'FAIL: geometry requires Jaguar SDK rmac for independent machine-code proof' >&2
  exit 1
fi
stage_collision_polygons "$@"
python3 build/native_geometry.py check > build/geometry_postbuild_check.log
python3 tests/test_native_geometry.py > build/geometry_postbuild_tests.log 2>&1
)


stage_gpu_trace() (
  set -euo pipefail
# Native runtime instrument is an emulator-only diagnostic: no original ROM or model modifications.
if [[ $# -lt 2 ]]; then
 echo 'Usage: build.sh retail.zip jaguar-sdk-directory [headless-virtualjaguar] [output.j64]' >&2
 exit 2
fi
cd "$(dirname "$0")"
python3 build/verify_collision_trace.py check
python3 tests/test_collision_trace.py > build/gpu_trace_prebuild_tests.log 2>&1
stage_contact_audit "$@"
python3 build/verify_collision_trace.py check
python3 tests/test_collision_trace.py > build/gpu_trace_postbuild_tests.log 2>&1
python3 - "$1" "${4:-Club_Drive.j64}" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import sys, hashlib
with ZipFile(sys.argv[1]) as z:
    names=[n for n in z.namelist() if n.lower().endswith(('.j64','.rom'))]
    if len(names)!=1:raise SystemExit('Retail reference ambiguous')
    original=z.read(names[0])
result=Path(sys.argv[2]).read_bytes()
if len(result)!=2097152 or result!=original:raise SystemExit('GPU_TRACE clean build differs from retail')
print('GPU_TRACE_CLEAN_ROM',len(result),hashlib.sha256(result).hexdigest())
PY
)


stage_models() (
  set -euo pipefail
# CLUB DRIVE (2026 reconstruction): native .MDL/.BND JSON authoring + PNG art.
# Caution: original Jaguar collision BSP is preserved, not recomputed.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
# Compile all twelve native authoring documents before the standard 68000
# source link; sync the lowercase car*.mdl aliases included from PLAY.S.
python3 build/native_model_pipeline.py compile
if [[ "${CLUB_ALLOW_NATIVE_MODEL_EDITS:-0}" == "1" ]]; then
  # An edited car point belongs to source-linked 68000 text, not the bank.
  # Rebuild the executable; do NOT take the audio_bank PNG-only incremental shortcut.
  REF="$(realpath "$1")"; SDK="$(realpath "$2")"; EMU="$(realpath "${3:-/bin/true}")"
  OUT="${4:-Club_Drive_model_edited.j64}"
  python3 build/png_art_pipeline.py compile
  CLUB_RUN_RELOCATION_AUDIT=0 CLUB_BUILD_RETAIL_SLOT=0 CLUB_RUN_EMULATOR_TEST=0 \
    stage_retail_link "$REF" "$SDK" "$EMU" Club_Drive_source_integrated.j64
  python3 build/rebuild_original_bank.py \
    --source Club_Drive_source_integrated.j64 --sdk "$SDK" \
    --reference "$REF" --output "$OUT" --allow-edited-resources \
    --manifest build/models_model_edited_index.json
  return 0
fi
stage_artwork "$1" "$2" "${3:-/bin/true}" "${4:-Club_Drive.j64}"
)


stage_native_tree() (
  set -euo pipefail
# Club Drive native_tree (2026 reconstruction): topology-aware native .MDL writer.
# Generated alternate trees are not linked into the clean Jaguar ROM.
# Maintain bsp_geometry's authoritative ASC geometry and original runtime model path.
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh retail-reference.zip jaguar-sdk-dir [emulator] [output.j64]' >&2
  exit 2
fi
cd "$(dirname "$0")"
python3 tests/test_native_tree.py > build/native_tree_native_tree_tests.log 2>&1
python3 tests/test_native_planes.py > build/native_tree_native_plane_tests.log 2>&1
python3 build/native_tree.py compile > build/native_tree_native_compile.log
python3 build/native_tree.py probe > build/native_tree_native_probe.log
python3 build/native_tree.py check > build/native_tree_native_check.log
python3 build/native_plane_audit.py compile > build/native_tree_plane_audit.log
python3 build/native_plane_audit.py check > build/native_tree_plane_check.log
if [[ -x "$2/tools/bin/rmac" ]]; then
  python3 build/assemble_native_probe.py --rmac "$2/tools/bin/rmac" > build/native_tree_assembler_probe.log
fi
# Deliberately builds only original, fixed-topology Jaguar runtime models.
stage_geometry_partitions "$@"
python3 build/native_tree.py check > build/native_tree_postbuild_check.log
python3 build/native_plane_audit.py check > build/native_tree_postbuild_plane_check.log
)


stage_retail_link() (
  set -euo pipefail
# ---------------------------------------------------------------------------
# CLUB DRIVE / RECONSTRUCTED 1994 + RETAIL-SUPPLEMENTED RELEASE BUILD (RETAIL_LINK)
# ---------------------------------------------------------------------------
# Original GAME/SYS/etc source and all 21 GPU modules are assembled normally.
# Late C code missing from surviving packet.s is a visibly marked, annotated
# retail opcode transcription, included as a normal assembler input.
# Historical 68000 linker padding is assembled as NOPs, not copied ROM code.
# RETAIL_LINK restores two short branches and eliminates the duplicate showcoords
# state; optional retail-slot mode is explicitly reference-data-dependent.
# ART.S is assembled, verified against the extracted art asset and gzip-packed
# so modifications to that original source participate in the rebuilt ROM.
# The supplied Jaguar SDK's jagcrypt re-authenticates every modified cartridge.
# ---------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
  echo 'Usage: build.sh reference.zip sdk_dir [virtualjaguar-headless] [output.j64]' >&2
  exit 2
fi
REF="$(realpath "$1")"
SDK="$(realpath "$2")"
EMU="$(realpath "${3:-/bin/true}")"
cd "$(dirname "$0")"
OUT="${4:-Club_Drive_source_integrated.j64}"
# The older builder repairs legacy macros and builds worlds/sounds/graphics.
# Skip its unreliable optional emulator wrapper: the explicit bootstrap_link validator is
# used separately and must never be treated as part of a compile pass.
stage_original_resources "$REF" "$SDK" build/retail_link_reference_hybrid.j64 > build/retail_link_legacy_seed.log 2>&1
GPU_VERIFY_FLAGS=()
if [[ "${CLUB_ALLOW_EDITED_WORLD_GPU:-0}" == "1" ]]; then
  GPU_VERIFY_FLAGS+=(--allow-edited-world-gpu)
fi
python3 build/verify_exact_gpu.py --reference "$REF" --before-container "${GPU_VERIFY_FLAGS[@]}"
python3 build/gpu_containerize.py "$REF" --fallback '' 
# Reassemble with module-specific historical branch rules after legacy steps.
JAGSDK="$SDK" python3 build/assemble_modules.py
# RESOURCES has already refreshed source_link_stage5.json. Its diagnostic link may
# exceed the cartridge size; the final retail_link linker is the authoritative one.
TAIL_EDIT_FLAGS=()
if [[ "${CLUB_ALLOW_EDITED_RETAIL_TAIL:-0}" == "1" ]]; then
  TAIL_EDIT_FLAGS+=(--allow-edited-retail-tail)
fi
python3 build/build_source_integrated_retail.py --reference "$REF" --sdk "$SDK" --output "$OUT" "${TAIL_EDIT_FLAGS[@]}"
python3 build/audit_source.py --reference "$REF" --source "$OUT"
python3 build/verify_world_gpu_retail.py --reference "$REF" --rom "$OUT" \
  --output build/retail_link_world_gpu_verification.json
# This read-only audit traces absolute addresses into the retail data and
# checks all five original Huffman tables without rewriting the executable.
# Disable for deliberate edits to INFLATE data or relocated code.
if [[ "${CLUB_RUN_RELOCATION_AUDIT:-1}" == 1 ]]; then
  python3 build/audit_data_relocations_retail.py --reference "$REF" --source "$OUT" \
    --json build/retail_link_relocation_audit.json
  # List all recovered data labels with their actual RLN locations. This
  # verifies original bytes without pretending their locations are original.
  python3 build/audit_retail_data_layout.py --reference "$REF" --source "$OUT" \
    --output build/retail_link_data_layout.json
  # Alternate ROM output: preserve original retail DATA addresses, but
  # replace the complete 68000/GPU executable with reassembled source bytes.
  # Requires a clean, exact-audited CPU baseline; edits to instruction bytes
  # must use assemble_retail_slot.py --allow-edited-cpu explicitly.
  if [[ "${CLUB_BUILD_RETAIL_SLOT:-1}" == 1 ]]; then
    python3 build/assemble_retail_slot.py --reference "$REF" --source "$OUT" \
      --sdk "$SDK" --audit build/retail_link_relocation_audit.json \
      --output Club_Drive_retail_slot.j64
  fi
fi
if [[ "${CLUB_RUN_EMULATOR_TEST:-0}" == 1 ]]; then
  if [[ ! -x "$EMU" ]]; then
    echo 'retail_link gameplay test requires an executable Virtual Jaguar path' >&2
    exit 2
  fi
  python3 build/validate_source_retail.py --reference "$REF" --source "$OUT" \
    --emulator "$EMU" --frames "${CLUB_TEST_FIELDS:-1800}" \
    --interval "${CLUB_TEST_INTERVAL:-600}" --timeout "${CLUB_TEST_TIMEOUT:-240}"
fi
printf '%s\n' "RETAIL_LINK PASS: exact-position late retail code + source-assembled GPU + original linker padding + editable ART.S"
sha256sum "$OUT"
)

# Build the cartridge. `make rom` passes paths relative to this script's root.
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 retail.zip jaguar-sdk-directory [headless-emulator] [output.j64]" >&2
  exit 2
fi
stage_source "$@"

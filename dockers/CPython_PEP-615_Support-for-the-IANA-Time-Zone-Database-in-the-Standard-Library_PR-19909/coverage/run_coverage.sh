#!/usr/bin/env bash
# LoLBench coverage runner for CPython PR-19909 (PEP 615: zoneinfo).
#
# zoneinfo is hybrid (Python + C extension); coverage must measure
# BOTH layers.  Strategy:
#
#   1. Apply solution.patch + eval_tests.patch on top of the gcov-
#      instrumented base build.
#   2. Re-run ./configure (configure.ac was patched) so setup.py picks
#      up the new Modules/_zoneinfo.c entry.
#   3. `make` builds the new C extension with the inherited
#      `CFLAGS="--coverage -O0 -g"` from the base layer, emitting
#      .gcno files next to the new .c sources.
#   4. Run F2P under `coverage run --source=Lib/zoneinfo ...` so
#      coverage.py traces Python execution under Lib/zoneinfo/*.py.
#      The same run also accumulates .gcda counters for the C
#      extension automatically (gcov writes counters at process
#      exit / atexit).
#   5. Snapshot the .gcda set, clear, then run P2P with both
#      coverage.py append + a fresh .gcda lane.
#   6. Emit per-file JSON for both lanes (coverage json + gcovr
#      --json) and feed into compute_coverage.py for the summary.
#
# Output:
#   /out/coverage_report.json   per-file + summary + tool_status
#
# Exit codes:
#   0 — all coverage tools succeeded; numbers are trustworthy.
#   2 — at least one tool failed; coverage_complete=false in report.
set -euo pipefail
PRIV=/opt/lolbench/private
CPYTHON=/workspace/cpython
PYTHON="$CPYTHON/python"
SUITE=${LOLBENCH_SUITE:-orig}

case "$SUITE" in
  orig|aug|union) ;;
  *) echo "[coverage] FATAL: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi
if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    echo "[coverage] WARN: LOLBENCH_SUITE=$SUITE but no sidecar shipped; falling back to orig" >&2
    SUITE=orig
fi

cd "$CPYTHON"
git config --global --add safe.directory "$CPYTHON"
git reset --hard >/dev/null 2>&1
# Do NOT git clean -fdx — wipes configure-generated files needed by make.

# Coverage measurement always applies BOTH patches.
git apply "$PRIV/solution.patch"
git apply "$PRIV/eval_tests.patch"
if [ "$SUITE" != "orig" ]; then
    git apply "$PRIV/eval_tests_aug.patch"
fi

# Re-run configure (configure.ac was patched) so setup.py picks up the
# new _zoneinfo extension recipe.  Without this, `make` would skip the
# new extension because setup.py only enumerates extensions configure
# already announced.
CFLAGS="--coverage -O0 -g" LDFLAGS="--coverage" \
    ./configure --prefix=/usr/local --enable-optimizations=no >/tmp/cov-configure.log 2>&1

# Build the new C extension (incremental — only _zoneinfo.c changes).
jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null)
: "${jobs:=$(nproc)}"
[ "$jobs" -lt 1 ] && jobs=1
make -j"$jobs" >/tmp/cov-rebuild.log 2>&1

# ---- Snapshot dirs ---------------------------------------------------
COV_F2P_PY=$PRIV/.coverage.f2p
COV_P2P_PY=$PRIV/.coverage.p2p
COV_F2P_PY_JSON=$PRIV/coverage_f2p.json
COV_P2P_PY_JSON=$PRIV/coverage_p2p.json
COV_F2P_C=$PRIV/cov_f2p_c
COV_P2P_C=$PRIV/cov_p2p_c
COV_F2P_C_JSON=$PRIV/coverage_f2p_c.json
COV_P2P_C_JSON=$PRIV/coverage_p2p_c.json

rm -f "$COV_F2P_PY" "$COV_P2P_PY" \
      "$COV_F2P_PY_JSON" "$COV_P2P_PY_JSON" \
      "$COV_F2P_C_JSON" "$COV_P2P_C_JSON"
rm -rf "$COV_F2P_C" "$COV_P2P_C"
mkdir -p "$COV_F2P_C" "$COV_P2P_C"

ZONEINFO_PY="$CPYTHON/Lib/zoneinfo"
ZONEINFO_C="$CPYTHON/Modules/_zoneinfo.c"
[ -d "$ZONEINFO_PY" ] || { echo "ERROR: $ZONEINFO_PY missing post-patch" >&2; exit 2; }
[ -f "$ZONEINFO_C" ]  || { echo "ERROR: $ZONEINFO_C missing post-patch" >&2; exit 2; }

# Clear any pre-existing .gcda from the base build.
find "$CPYTHON" -name '*.gcda' -delete

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
    mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

case "$SUITE" in
  orig)
    FAIL_TO_PASS=("${FAIL_TO_PASS_ORIG[@]}")
    PASS_TO_PASS=("${PASS_TO_PASS_ORIG[@]}")
    ;;
  aug)
    FAIL_TO_PASS=("${FAIL_TO_PASS_AUG[@]}")
    PASS_TO_PASS=("${PASS_TO_PASS_AUG[@]}")
    ;;
  union)
    FAIL_TO_PASS=("${FAIL_TO_PASS_ORIG[@]}" "${FAIL_TO_PASS_AUG[@]}")
    PASS_TO_PASS=("${PASS_TO_PASS_ORIG[@]}" "${PASS_TO_PASS_AUG[@]}")
    ;;
esac

F2P_EFFECTIVE=$PRIV/f2p_effective.txt
P2P_EFFECTIVE=$PRIV/p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" > "$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" > "$P2P_EFFECTIVE"

# Helper: run one unittest id, captures both PY coverage trace + C gcda.
run_one() {
    local data_file=$1; shift
    local tid=$1; shift
    local out rc
    set +e
    out=$( COVERAGE_FILE="$data_file" \
        "$PYTHON" -m coverage run --append \
                --source="$ZONEINFO_PY" \
                --branch \
                -m unittest -v "$tid" 2>&1 )
    rc=$?
    set -e
    if echo "$out" | grep -qE "^(OK|ok)$"; then echo PASSED
    elif echo "$out" | grep -qE "^FAILED"; then
        if echo "$out" | grep -q "errors="; then echo ERROR
        else echo FAILED; fi
    elif [ "$rc" -ne 0 ]; then echo ERROR
    else echo PASSED; fi
}

# ---- Run F2P --------------------------------------------------------
F2P_VERDICTS=$PRIV/.f2p_verdicts.txt
: > "$F2P_VERDICTS"
while IFS= read -r tid; do
    [ -z "$tid" ] && continue
    v=$(run_one "$COV_F2P_PY" "$tid" || echo ERROR)
    echo "$tid $v" >> "$F2P_VERDICTS"
done < "$F2P_EFFECTIVE"

# Snapshot .gcda then clear.
(cd "$CPYTHON" && find . -name '*.gcda' -print0 | tar -cf - --null -T -) | \
    (cd "$COV_F2P_C" && tar -xf -) || true
find "$CPYTHON" -name '*.gcda' -delete

# ---- Run P2P --------------------------------------------------------
P2P_VERDICTS=$PRIV/.p2p_verdicts.txt
: > "$P2P_VERDICTS"
while IFS= read -r tid; do
    [ -z "$tid" ] && continue
    v=$(run_one "$COV_P2P_PY" "$tid" || echo ERROR)
    echo "$tid $v" >> "$P2P_VERDICTS"
done < "$P2P_EFFECTIVE"

(cd "$CPYTHON" && find . -name '*.gcda' -print0 | tar -cf - --null -T -) | \
    (cd "$COV_P2P_C" && tar -xf -) || true
find "$CPYTHON" -name '*.gcda' -delete

# ---- Emit coverage JSON for each lane -------------------------------
F2P_PY_OK=true; P2P_PY_OK=true; F2P_C_OK=true; P2P_C_OK=true

if [ -f "$COV_F2P_PY" ]; then
    COVERAGE_FILE="$COV_F2P_PY" "$PYTHON" -m coverage json --pretty-print \
        -o "$COV_F2P_PY_JSON" 2>/tmp/cov-f2p-py.err || F2P_PY_OK=false
else
    F2P_PY_OK=false
fi
if [ -f "$COV_P2P_PY" ]; then
    COVERAGE_FILE="$COV_P2P_PY" "$PYTHON" -m coverage json --pretty-print \
        -o "$COV_P2P_PY_JSON" 2>/tmp/cov-p2p-py.err || P2P_PY_OK=false
else
    P2P_PY_OK=false
fi

gcovr_one() {
    local snap_dir=$1 out_json=$2 err_marker=$3
    find "$CPYTHON" -name '*.gcda' -delete
    (cd "$snap_dir" && tar -cf - .) | (cd "$CPYTHON" && tar -xf -) 2>/dev/null || true
    if gcovr --json --filter 'Modules/_zoneinfo\.c' \
             --root "$CPYTHON" -o "$out_json" 2>/tmp/$err_marker; then
        return 0
    else
        return 1
    fi
}

gcovr_one "$COV_F2P_C" "$COV_F2P_C_JSON" "cov-f2p-c.err" || F2P_C_OK=false
gcovr_one "$COV_P2P_C" "$COV_P2P_C_JSON" "cov-p2p-c.err" || P2P_C_OK=false

# ---- Compute final report -------------------------------------------
"$PYTHON" "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --f2p-py-json "$COV_F2P_PY_JSON" \
    --p2p-py-json "$COV_P2P_PY_JSON" \
    --f2p-c-json  "$COV_F2P_C_JSON" \
    --p2p-c-json  "$COV_P2P_C_JSON" \
    --f2p-verdicts "$F2P_VERDICTS" \
    --p2p-verdicts "$P2P_VERDICTS" \
    --f2p-py-ok "$F2P_PY_OK" \
    --p2p-py-ok "$P2P_PY_OK" \
    --f2p-c-ok  "$F2P_C_OK" \
    --p2p-c-ok  "$P2P_C_OK" \
    --out "/out/coverage_report_${SUITE}.json"

if [ "$SUITE" = "orig" ]; then
    cp "/out/coverage_report_${SUITE}.json" /out/coverage_report.json
else
    if [ "$SUITE" != "aug" ]; then
        cp "/out/coverage_report_${SUITE}.json" /out/coverage_report_aug.json
    fi
fi
cp "/out/coverage_report_${SUITE}.json" "$PRIV/coverage_report.json"

"$PYTHON" -c "
import json, sys
r = json.load(open('/out/coverage_report_${SUITE}.json'))
sys.exit(0 if r.get('coverage_complete') else 2)
"

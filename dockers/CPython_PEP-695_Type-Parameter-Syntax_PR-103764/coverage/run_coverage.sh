#!/usr/bin/env bash
# LoLBench coverage runner for CPython PR-103764 (PEP 695: Type
# Parameter Syntax).
#
# PEP 695 modifies BOTH C (34 source/header files: parser, AST,
# compile, symtable, opcodes, typevarobject NEW + many internal
# headers) AND Python (5 files: Lib/typing.py + Lib/ast.py +
# Lib/keyword.py + Lib/opcode.py + Lib/importlib/_bootstrap_external.py);
# coverage must measure both layers. Strategy:
#
#   1. Apply solution.patch + eval_tests.patch on top of the gcov-
#      instrumented base build.
#   2. `make` rebuilds touched C files with the inherited gcov flags;
#      Grammar/python.gram and Parser/Python.asdl are regenerated
#      automatically. No reconfigure needed.
#   3. Run F2P under `coverage run --include=Lib/typing.py,Lib/ast.py,
#      Lib/keyword.py,Lib/opcode.py,Lib/importlib/_bootstrap_external.py ...`
#      so coverage.py traces only the 5 Python files in solution.patch.
#      The same run also accumulates .gcda counters for every CPython
#      .c file (we filter to the 34 PEP-695 ones with `gcovr --filter`).
#   4. Snapshot .gcda, clear, then run P2P likewise.
#   5. Emit per-file JSON for both lanes (coverage json + gcovr --json)
#      and feed into compute_coverage.py for the summary.
#
# Output:
#   /out/coverage_report_${SUITE}.json   per-file + summary + tool_status
#   /out/coverage_report.json            compatibility copy of the selected suite
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
  *) echo "ERROR: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi
if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    echo "WARN: LOLBENCH_SUITE=$SUITE but no sidecar shipped; falling back to orig" >&2
    SUITE=orig
fi

cd "$CPYTHON"
git config --global --add safe.directory "$CPYTHON"
git reset --hard >/dev/null 2>&1
# Do NOT git clean -fdx — wipes configure-generated files needed by make.

# Coverage measurement always applies BOTH patches.
git apply "$PRIV/solution.patch"
git apply "$PRIV/eval_tests.patch"
if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
    git apply "$PRIV/eval_tests_aug.patch"
fi

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
    mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

FAIL_TO_PASS=()
PASS_TO_PASS=()
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

F2P_EFFECTIVE=$PRIV/.f2p_effective.txt
P2P_EFFECTIVE=$PRIV/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" > "$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" > "$P2P_EFFECTIVE"

# PEP 695 does not touch configure.ac/Makefile.pre.in/pyconfig.h.in,
# so no reconfigure is needed. `make` alone rebuilds the touched C
# files (parser.c, compile.c, symtable.c, ast.c, Python-ast.c,
# intrinsics.c, typevarobject.c, _typingmodule.c) incrementally,
# regenerating parser.c and Python-ast.c from python.gram + Python.asdl
# along the way, and preserving the gcov --coverage flags baked into
# the base build.
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

# Python sources whose F2P/P2P coverage to measure (coverage.py --source
# accepts files via individual --include flags, so we list the 2 PEP-695
# stdlib edits explicitly).
PY_SRC_TYPING="$CPYTHON/Lib/typing.py"
PY_SRC_AST="$CPYTHON/Lib/ast.py"
PY_SRC_KEYWORD="$CPYTHON/Lib/keyword.py"
PY_SRC_OPCODE="$CPYTHON/Lib/opcode.py"
PY_SRC_BOOT="$CPYTHON/Lib/importlib/_bootstrap_external.py"
for f in "$PY_SRC_TYPING" "$PY_SRC_AST" "$PY_SRC_KEYWORD" "$PY_SRC_OPCODE" "$PY_SRC_BOOT"; do
    [ -f "$f" ] || { echo "ERROR: $f missing post-patch" >&2; exit 2; }
done
PY_INCLUDE="$PY_SRC_TYPING,$PY_SRC_AST,$PY_SRC_KEYWORD,$PY_SRC_OPCODE,$PY_SRC_BOOT"

# Clear any pre-existing .gcda from the base build.
find "$CPYTHON" -name '*.gcda' -delete

# Helper: run one unittest id, captures both PY coverage trace + C gcda.
run_one() {
    local data_file=$1; shift
    local tid=$1; shift
    local out rc
    set +e
    out=$( COVERAGE_FILE="$data_file" \
        "$PYTHON" -m coverage run --append \
                --include="$PY_INCLUDE" \
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

emit_py_json() {
    local data=$1 out_json=$2
    # If no .coverage data file was written at all, the lane simply touched
    # no Python file in --include= — emit an empty json and treat as OK.
    if [ ! -f "$data" ]; then
        echo '{"files": {}}' > "$out_json"
        return 0
    fi
    # `coverage json` exits 1 + prints "No data to report." to STDOUT (not
    # stderr) when there are zero covered statements (e.g. F2P here only
    # exercises C paths and never executes any file in --include=).  That's
    # not a tool failure; emit an empty json and treat OK.
    COVERAGE_FILE="$data" "$PYTHON" -m coverage json --pretty-print \
            -o "$out_json" >/tmp/cov-py.out 2>/tmp/cov-py.err
    rc=$?
    if [ "$rc" -eq 0 ]; then
        [ -s "$out_json" ] || echo '{"files": {}}' > "$out_json"
        return 0
    fi
    if grep -q "No data to report" /tmp/cov-py.out /tmp/cov-py.err 2>/dev/null; then
        echo '{"files": {}}' > "$out_json"
        return 0
    fi
    return 1
}

if ! emit_py_json "$COV_F2P_PY" "$COV_F2P_PY_JSON"; then
    F2P_PY_OK=false
fi
if ! emit_py_json "$COV_P2P_PY" "$COV_P2P_PY_JSON"; then
    P2P_PY_OK=false
fi

gcovr_one() {
    local snap_dir=$1 out_json=$2 err_marker=$3
    find "$CPYTHON" -name '*.gcda' -delete
    (cd "$snap_dir" && tar -cf - .) | (cd "$CPYTHON" && tar -xf -) 2>/dev/null || true
    if gcovr --json \
             --filter 'Python/(compile|symtable|ast|ast_opt|Python-ast|bytecodes|intrinsics|pylifecycle)\.c' \
             --filter 'Parser/(parser|action_helpers)\.c' \
             --filter 'Objects/(typevarobject|funcobject|typeobject|unionobject|object)\.c' \
             --filter 'Objects/clinic/typevarobject\.c\.h' \
             --filter 'Modules/_typingmodule\.c' \
             --filter 'Include/(opcode|cpython/funcobject)\.h' \
             --filter 'Include/internal/pycore_(ast|ast_state|function|global_objects|global_objects_fini_generated|global_strings|intrinsics|opcode|runtime_init_generated|symtable|typevarobject|unicodeobject_generated)\.h' \
             --root "$CPYTHON" -o "$out_json" 2>/tmp/$err_marker; then
        return 0
    else
        return 1
    fi
}

gcovr_one "$COV_F2P_C" "$COV_F2P_C_JSON" "cov-f2p-c.err" || F2P_C_OK=false
gcovr_one "$COV_P2P_C" "$COV_P2P_C_JSON" "cov-p2p-c.err" || P2P_C_OK=false

# ---- Compute final report -------------------------------------------
OUT_REPORT="/out/coverage_report_${SUITE}.json"
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
    --out "$OUT_REPORT"

cp "$OUT_REPORT" /out/coverage_report.json
cp "$OUT_REPORT" "$PRIV/coverage_report.json"

if [ "${LOLBENCH_COVERAGE_DEBUG:-0}" = "1" ]; then
    cp "$COV_F2P_PY_JSON" /out/coverage_f2p_py.json
    cp "$COV_P2P_PY_JSON" /out/coverage_p2p_py.json
    cp "$COV_F2P_C_JSON" /out/coverage_f2p_c.json
    cp "$COV_P2P_C_JSON" /out/coverage_p2p_c.json
fi

"$PYTHON" -c "
import json, sys
r = json.load(open('/out/coverage_report.json'))
sys.exit(0 if r.get('coverage_complete') else 2)
"

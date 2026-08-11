#!/usr/bin/env bash
# LoLBench coverage runner for CPython PR-29581 (PEP 654: Exception Groups and except*).
#
# Applies solution.patch + eval_tests.patch on top of base_commit and
# measures F2P/P2P line coverage of solution.patch using gcov: every
# .c file under /workspace/cpython has a sibling .gcno (compile-time
# basic-block map) and accumulates a sibling .gcda (run-time counter
# snapshot) when the instrumented ./python exits.  We run F2P with
# coverage, snapshot the .gcda set, clear it, run P2P, snapshot again,
# then ask gcovr to render each snapshot as JSON and feed both to
# compute_coverage.py.
#
# Runs everything as root — the container is only ever invoked by the
#
# Output:
#   /out/coverage_report.json   per-file + summary + tool_status
#   /opt/lolbench/private/coverage_report.json   grader copy
#
# Exit codes:
#   0 — all coverage tools succeeded; numbers are trustworthy.
#   2 — at least one tool failed; coverage_complete=false in the report.
#       Numbers are partial; do not use externally without a caveat.
#
# `set -e` (Codex Medium-2 finding, carries over from PEP-634): so a
# failed `git apply` or `make` aborts the script instead of silently
# rolling forward into test execution + coverage analysis with a stale
# or partially-patched binary.
set -euo pipefail
PRIV=/opt/lolbench/private
CPYTHON=/workspace/cpython
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
# NOTE: do NOT git clean -fdx — that would wipe Misc/python-config.sh
# and the .gcno files the docker build just emitted.  Every container
# is fresh (docker run --rm) so a tracked-file rewind is enough.

# Coverage measurement always applies BOTH patches.
git apply "$PRIV/solution.patch"
git apply "$PRIV/eval_tests.patch"
if [ "$SUITE" != "orig" ]; then
    git apply "$PRIV/eval_tests_aug.patch"
fi

COV_F2P=$PRIV/cov_f2p
COV_P2P=$PRIV/cov_p2p
rm -rf "$COV_F2P" "$COV_P2P"
mkdir -p "$COV_F2P" "$COV_P2P"

# ---- Reconfigure if solution.patch touched configure.ac / pyconfig.h.in --
needs_reconfig=0
if grep -qE '^(diff --git a/(configure(\.ac)?|pyconfig\.h\.in|Makefile\.pre\.in)) ' \
       "$PRIV/solution.patch"; then
    needs_reconfig=1
fi

(
  set -e
  cd "$CPYTHON"
  if [ "$needs_reconfig" -eq 1 ]; then
    CFLAGS="--coverage -O0 -g" \
    LDFLAGS="--coverage" \
    ./configure --prefix=/usr/local --enable-optimizations=no
  fi
  jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null)
  : "${jobs:=$(nproc)}"
  [ "$jobs" -lt 1 ] && jobs=1
  make -j"$jobs"
) 2>&1 | tail -30

# ---- Clear stale .gcda from the bake-time build ----------------------
# .gcno files from docker build stay (they're the structural map);
# .gcda files would contaminate the F2P snapshot with build-time hits.
find "$CPYTHON" -name '*.gcda' -delete 2>/dev/null || true

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

# Mirror the eval-image runner: drive unittest.TestLoader programmatically
# inside the instrumented ./python.  The same script in run_tests.sh works
# unchanged here.
cat > /tmp/lolbench_aggregate.py <<'PYRUN'
import json, os, sys, unittest
from io import StringIO

def load_ids(path):
    with open(path, "r") as f:
        return [line.strip() for line in f if line.strip()]

def run_one(test_id):
    loader = unittest.TestLoader()
    try:
        suite = loader.loadTestsFromName(test_id)
    except Exception as exc:
        return "ERROR", f"load_failed: {type(exc).__name__}: {exc}"[:1000]
    n = suite.countTestCases()
    if n == 0:
        return "ERROR", "no_tests_collected"
    if n > 1:
        return "ERROR", f"ambiguous: {n} cases for one id"
    stream = StringIO()
    result = unittest.TextTestRunner(stream=stream, verbosity=0, buffer=False).run(suite)
    if result.errors:   return "ERROR",   str(result.errors[0][1])[-1000:]
    if result.failures: return "FAILED",  str(result.failures[0][1])[-1000:]
    if result.skipped:  return "SKIPPED", str(result.skipped[0][1])[-1000:]
    return "PASSED", ""

ids = load_ids(os.environ["LOLBENCH_IDS_FILE"])
verdicts = {tid: run_one(tid) for tid in ids}
json.dump({tid: {"verdict": v, "msg": m} for tid, (v, m) in verdicts.items()},
          sys.stdout, indent=2)
sys.stdout.write("\n")
PYRUN

run_with_coverage() {
    local ids_file=$1 snapshot_dir=$2 label=$3
    echo "=== $label (instrumented) ==="
    (
        cd "$CPYTHON"
        LOLBENCH_IDS_FILE="$ids_file" \
        PYTHONDONTWRITEBYTECODE=1 \
        ./python /tmp/lolbench_aggregate.py
    ) > "$snapshot_dir/results.json" 2> "$snapshot_dir/runner.err"
    # gcov .gcda files land next to their .gcno (under /workspace/cpython/);
    # tar them up so a later run does not clobber the snapshot.
    (cd "$CPYTHON" && \
     find . -name '*.gcda' -print0 \
     | tar -czf "$snapshot_dir/gcda.tar.gz" --null -T - 2>/dev/null) || true
    find "$CPYTHON" -name '*.gcda' -delete 2>/dev/null || true
    echo "  results: $(jq -r 'to_entries | map(.value.verdict) | group_by(.) | map({(.[0]): length}) | add' "$snapshot_dir/results.json" 2>/dev/null || tail -3 "$snapshot_dir/results.json")"
    echo "  gcda snapshot: $(du -h "$snapshot_dir/gcda.tar.gz" 2>/dev/null | awk '{print $1}')"
}

run_with_coverage "$F2P_EFFECTIVE" "$COV_F2P" "F2P"
run_with_coverage "$P2P_EFFECTIVE" "$COV_P2P" "P2P"

# ---- Analyse + emit report -------------------------------------------
mkdir -p /out
set +e
OUT_REPORT="/out/coverage_report_${SUITE}.json"
python3 /opt/lolbench/private/compute_coverage.py \
    --solution-patch "$PRIV/solution.patch" \
    --cpython-root "$CPYTHON" \
    --f2p-cov "$COV_F2P" \
    --p2p-cov "$COV_P2P" \
    --out "$OUT_REPORT"
analyse_rc=$?
set -e
cp "$OUT_REPORT" /out/coverage_report.json
cp "$OUT_REPORT" "$PRIV/coverage_report.json" 2>/dev/null || true

echo
echo "=== coverage_report summary ==="
python3 - "$OUT_REPORT" <<'PY'
import json
import sys
r = json.load(open(sys.argv[1]))
s = r["summary"]
complete = r.get("coverage_complete", False)
print(f"  coverage_complete                  : {complete}")
print(f"  lines added by solution.patch      : {s['lines_in_patch_total']}")
print(f"  executable subset (denominator)    : {s['executable_lines_in_patch']}")
print(f"  F2P covered                        : {s['f2p_covered']:5d}  ({s['f2p_pct']}%)")
print(f"  P2P covered                        : {s['p2p_covered']:5d}  ({s['p2p_pct']}%)")
print(f"  F2P union P2P covered              : {s['union_covered']:5d}  ({s['union_pct']}%)")
if not complete:
    print("\n  tool_status:")
    for name, st in r.get("tool_status", {}).items():
        marker = "ok" if st.get("ok") else "FAIL"
        print(f"    {marker:4s}  {name}  {st.get('error','') or ''}")
PY

exit $analyse_rc

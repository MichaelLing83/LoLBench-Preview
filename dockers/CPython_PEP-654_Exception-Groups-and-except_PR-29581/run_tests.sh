#!/usr/bin/env bash
# LoLBench runner for CPython PR-29581 (PEP 654).
#
# The agent does NOT execute code inside this container.  The evaluator
# runs the container after the agent submits a solution.patch; the
# container applies the patch, builds, runs the hidden F2P/P2P selection,
# and writes a sanitized report.  Because the container is only ever run
# by a trusted evaluator, every step runs as root — no agent UID, no
# runuser, no chown gymnastics.
#
# Eval contract (default mode):
#   docker run --rm \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/cpython-pr-29581:1
#   → writes /out/agent_report.json (sanitized).
#
# Validation modes (used by the benchmark builders):
#   LOLBENCH_MODE=validate_pre   # F2P FAIL/ERROR, P2P PASS
#   LOLBENCH_MODE=validate_post  # all PASS
#
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
CPYTHON=$WS/cpython
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}

case "$SUITE" in
  orig|aug|union) ;;
  *) echo "[run_tests] FATAL: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi
if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    echo "[run_tests] WARN: LOLBENCH_SUITE=$SUITE but no sidecar shipped; falling back to orig" >&2
    SUITE=orig
fi

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }
die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

FAIL_TO_PASS=()
PASS_TO_PASS=()

# emit_error <category> <applied:true|false> <build_status>
emit_error() {
    local cat=$1 applied=$2 build_status=$3
    # bash forbids combining `#` length op with `:-` default
    # (`${#arr[@]:-0}` is a parse error). The arrays are always defined
    # by the mapfile calls below before any die→emit_error can fire, so
    # plain `${#arr[@]}` is safe.
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" <<'EOF' >/out/agent_report.json
import json, os, sys
cat, applied_s, build_s, f2p_n, p2p_n = sys.argv[1:6]
applied = applied_s.lower() == "true"
print(json.dumps({
  "instance_id": "CPython_PEP-654_Exception-Groups-and-except_PR-29581",
  "suite": os.environ.get("LOLBENCH_EFFECTIVE_SUITE", "orig"),
  "augmentation_available": os.environ.get("LOLBENCH_HAS_AUG", "0") == "1",
  "applied": applied,
  "build": {"status": build_s},
  "f2p": {"passed":0,"failed":0,"errored":int(f2p_n),"skipped":0,"total":int(f2p_n)},
  "p2p": {"passed":0,"failed":0,"errored":int(p2p_n),"skipped":0,"total":int(p2p_n)},
  "resolved": False,
  "error_categories": [cat]
}, indent=2))
EOF
}

export LOLBENCH_EFFECTIVE_SUITE="$SUITE"
export LOLBENCH_HAS_AUG="$HAS_AUG"

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
    mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

# Sanity-check: spec and selector files must agree.
python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" \
         "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" "$HAS_AUG" <<'EOF' || die "spec/selector mismatch"
import json, sys
spec_path, f2p, p2p, f2p_aug, p2p_aug, has_aug = sys.argv[1:7]
spec = json.load(open(spec_path))
def ids(path):
    return [l.strip() for l in open(path) if l.strip()]
ok = spec["fail_to_pass"] == ids(f2p) and spec["pass_to_pass"] == ids(p2p)
if has_aug == "1":
    aug = spec.get("augmented", {})
    aug_f2p = ids(f2p_aug)
    aug_p2p = ids(p2p_aug)
    triage = aug.get("triage", {})
    f2p_triage = triage.get("fail_to_pass", {})
    p2p_triage = triage.get("pass_to_pass", {})
    ok = ok and aug.get("fail_to_pass") == aug_f2p \
            and aug.get("pass_to_pass") == aug_p2p \
            and set(f2p_triage) == set(aug_f2p) \
            and set(p2p_triage) == set(aug_p2p) \
            and bool(triage.get("test_level_policy"))
    for tid in aug_f2p:
        entry = f2p_triage.get(tid, {})
        ok = ok and bool(entry.get("requirement_sections")) \
                and bool(entry.get("public_surface")) \
                and isinstance(entry.get("mutants_targeted"), list) \
                and bool(entry.get("rationale"))
    for tid in aug_p2p:
        entry = p2p_triage.get(tid, {})
        ok = ok and bool(entry.get("requirement_sections")) \
                and bool(entry.get("public_surface")) \
                and bool(entry.get("rationale"))
sys.exit(0 if ok else 1)
EOF

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

# ---- Pick source-side patch by mode ----------------------------------
SRC_PATCH=""
case "$MODE" in
  validate_pre)
    SRC_PATCH="" ;;
  validate_post)
    SRC_PATCH="$PRIV/solution.patch" ;;
  eval)
    if [ ! -f /in/solution.patch ]; then
      log "no /in/solution.patch mounted"
      emit_error missing_solution_patch false skipped
      exit 0
    fi
    cp /in/solution.patch "$PRIV/agent_patch.diff"
    chmod 0600 "$PRIV/agent_patch.diff"
    SRC_PATCH="$PRIV/agent_patch.diff" ;;
  *)
    die "unknown LOLBENCH_MODE=$MODE" ;;
esac

# ---- Reset workspace + apply patches ---------------------------------
cd "$CPYTHON"
git config --global --add safe.directory "$CPYTHON"
# `git reset --hard` is enough: every container is fresh (docker run --rm),
# so there is nothing to clean from a "previous run" inside this image —
# the layer state baked at build time is the only state we need to roll
# back to. `git clean -fdx` was removed because it deleted configure-
# generated files (Misc/python-config.sh, python-config.py, …) that are
# untracked but load-bearing for `make`; without them the next make
# invocation dies with "No rule to make target Misc/python-config.sh".
git reset --hard >/dev/null 2>&1

if [ -n "$SRC_PATCH" ]; then
  if ! git apply --check "$SRC_PATCH" 2>/tmp/apply.err; then
    log "source patch did not apply cleanly:"
    cat /tmp/apply.err >&2
    emit_error patch_apply_failure false skipped
    exit 0
  fi
  git apply "$SRC_PATCH"
  # LoLBench eval-patch-collision guard (re-verify remediation): if the agent patch touched files the
  # eval test patches own (test fixtures the agent must not modify), restore
  # those paths (both sides of every diff/rename) to the base state so
  # eval_tests(.aug).patch always applies. Agent source changes are preserved.
  for _lb_ep in "$PRIV/eval_helpers.patch" "$PRIV/eval_tests.patch" "$PRIV/eval_tests_aug.patch"; do
    [ -f "$_lb_ep" ] || continue
    { sed -n 's|^diff --git a/\(.*\) b/\(.*\)$|\1\n\2|p' "$_lb_ep"
      sed -n 's|^rename from \(.*\)$|\1|p' "$_lb_ep"
      sed -n 's|^rename to \(.*\)$|\1|p' "$_lb_ep"; } | sort -u | while read -r _lb_f; do
      [ -n "$_lb_f" ] || continue
      git checkout HEAD -- "$_lb_f" >/dev/null 2>&1 || rm -f "$_lb_f" >/dev/null 2>&1 || true
    done
  done
fi

if ! git apply --check "$PRIV/eval_tests.patch" 2>/tmp/apply.err; then
  log "eval_tests.patch did not apply cleanly on top of source patch:"
  cat /tmp/apply.err >&2
  emit_error eval_patch_apply_failure true skipped
  exit 0
fi
git apply "$PRIV/eval_tests.patch"

if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
  if ! git apply --check "$PRIV/eval_tests_aug.patch" 2>/tmp/apply.err; then
    log "eval_tests_aug.patch did not apply cleanly on top of eval_tests.patch:"
    cat /tmp/apply.err >&2
    emit_error eval_aug_patch_apply_failure true skipped
    exit 0
  fi
  git apply "$PRIV/eval_tests_aug.patch"
fi

# ---- Build -----------------------------------------------------------
# CPython is incremental: Make sees the changed C/H files and rebuilds
# only what's needed.  For PEP 654 solution.patch touches Grammar/python.gram,
# Parser/parser.c (regenerated, +2770/-1826 lines), Parser/Python.asdl,
# Python/compile.c, ceval.c, ast.c, ast_opt.c, symtable.c, generated
# Python-ast.c/pycore_ast.h, opcode.h/opcode_targets.h, plus
# Objects/exceptions.c (ExceptionGroup-split machinery) and
# Objects/frameobject.c (frame f_iblock bookkeeping for the new opcode).
BUILD_LOG=$WS/.build.log
: >"$BUILD_LOG"

# If solution.patch touched configure.ac or pyconfig.h.in, re-run autoreconf
# + configure.  Otherwise a plain `make` picks up the changes.
needs_reconfig=0
if [ -n "$SRC_PATCH" ]; then
  if grep -qE '^(diff --git a/(configure(\.ac)?|pyconfig\.h\.in|Makefile\.pre\.in)) ' "$SRC_PATCH"; then
    needs_reconfig=1
  fi
fi

(
  set -e
  cd "$CPYTHON"
  if [ "$needs_reconfig" -eq 1 ]; then
    # configure is shipped pre-generated; re-running it picks up changes
    # to configure or pyconfig.h.in directly without autoreconf.
    ./configure --prefix=/usr/local --enable-optimizations=no
  fi
  # Cap parallelism to the container's CPU quota.  `nproc` reports the
  # *host* core count even when the container is started with --cpus N
  # (it ignores cgroup cpu.max), so on an M-series Mac that sets --cpus 4
  # we would otherwise launch -j14 against 4 cores and thrash.  Read the
  # actual quota from cgroup v2 (cpu.max = "<quota> <period>" → cores =
  # quota/period) and fall back to nproc only if the file is missing.
  jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null)
  : "${jobs:=$(nproc)}"
  [ "$jobs" -lt 1 ] && jobs=1
  make -j"$jobs"
) >"$BUILD_LOG" 2>&1
build_status=$?

if [ "$build_status" -ne 0 ]; then
  log "build failed (rc=$build_status); tail of build log:"
  tail -60 "$BUILD_LOG" >&2 || true
  emit_error build_failure true failed
  exit 0
fi

# ---- Run tests -------------------------------------------------------
# CPython test IDs are dotted python paths.  Earlier revisions of this
# script ran `./python -m unittest -v $IDS` and grepped the textual
# output, but unittest -v actually prints two formats depending on
# whether a method has a docstring:
#
#   test_x (test.module.Class) ... ok                  # no docstring
#   test_x (test.module.Class)
#   The leading line of the docstring ... ok           # with docstring
#
# Every selected F2P test has a docstring, so the regex parser would
# misclassify successful runs as ERROR.  We therefore do NOT parse text:
# instead we drive unittest.TestLoader/TextTestRunner programmatically
# inside the freshly-built ./python and write a structured JSON result.
#
# Each test id is loaded and run in isolation so a load-time error in
# one id never poisons another.  Pre-state F2P fails at module-load time
# for test_except_star.py (uses except* syntax that the pre-PR parser
# does not recognise → SyntaxError → ImportError → ERROR for all 49
# methods); the one F2P from test_unparse.py fails at runtime because
# ast.unparse doesn't know how to render ast.TryStar (the node class
# doesn't exist at base_commit) → AttributeError → ERROR.

F2P_RESULTS_JSON=$WS/.f2p_results.json
P2P_RESULTS_JSON=$WS/.p2p_results.json
F2P_RUNNER_ERR=$WS/.f2p_runner.err
P2P_RUNNER_ERR=$WS/.p2p_runner.err
F2P_EFFECTIVE=$WS/.f2p_effective.txt
P2P_EFFECTIVE=$WS/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" > "$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" > "$P2P_EFFECTIVE"

# Emit the per-id runner as a one-shot Python script the freshly-built
# ./python will execute.  Using ./python (not the system python3)
# guarantees we are exercising the version we just built.  F2P and P2P
# run in separate interpreter processes so a source-level crash while
# exercising a failing requirement cannot mask unrelated P2P behavior.
cat > /tmp/lolbench_lane.py <<'PYRUN'
"""Run one lane of unittest ids under the freshly-built ./python.

For each id:
  * unittest.TestLoader.loadTestsFromName(id) imports the module + class
    and resolves the leaf method.  Any SyntaxError (except* not yet
    recognised at base_commit) or AttributeError (ast.TryStar absent)
    becomes a clean ERROR — exactly the pre-state behavior we want
    for F2P.
  * TextTestRunner.run() collects errors/failures/skips/passes.
  * Output is one JSON document on stdout — no text parsing.
"""
import json
import os
import sys
import unittest
from io import StringIO


def load_ids(path):
    with open(path, "r") as f:
        return [line.strip() for line in f if line.strip()]


def run_one(test_id):
    loader = unittest.TestLoader()
    try:
        suite = loader.loadTestsFromName(test_id)
    except Exception as exc:  # ImportError, AttributeError, etc.
        return "ERROR", f"load_failed: {type(exc).__name__}: {exc}"[:2000]
    n = suite.countTestCases()
    if n == 0:
        # A loadTestsFromName that resolves to a class with no tests, or
        # whose discovery silently dropped the leaf, is treated as ERROR
        # — the test did not run.
        return "ERROR", "no_tests_collected"
    if n > 1:
        return "ERROR", f"ambiguous: {n} cases collected for one id"
    stream = StringIO()
    try:
        result = unittest.TextTestRunner(
            stream=stream, verbosity=0, buffer=False
        ).run(suite)
    except SystemExit as exc:
        # Some tests call sys.exit; unittest normally catches but be safe.
        return "ERROR", f"runner_systemexit: {exc.code}"[:2000]
    except Exception as exc:
        return "ERROR", f"runner_crashed: {type(exc).__name__}: {exc}"[:2000]
    if result.testsRun != 1:
        return "ERROR", f"unexpected_testsRun={result.testsRun}"
    if result.errors:
        return "ERROR", str(result.errors[0][1])[-2000:]
    if result.failures:
        return "FAILED", str(result.failures[0][1])[-2000:]
    if result.skipped:
        return "SKIPPED", str(result.skipped[0][1])[-2000:]
    # An expectedFailure/unexpectedSuccess count is not part of any
    # selection lane in this benchmark; treat as PASSED if the runner
    # said the test ran without failure/error/skip.
    return "PASSED", ""


def aggregate(ids):
    out = {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []}
    detail = {}
    for tid in ids:
        verdict, msg = run_one(tid)
        out[verdict].append(tid)
        detail[tid] = {"verdict": verdict, "msg": msg}
    return out, detail


lane_ids = load_ids(os.environ["LOLBENCH_IDS_FILE"])
results, detail = aggregate(lane_ids)
json.dump(
    {
        "results": results,
        "detail": detail,
    },
    sys.stdout,
)
sys.stdout.write("\n")
PYRUN

run_lane() {
  local ids_file=$1 results_file=$2 err_file=$3
  (
    cd "$CPYTHON"
    LOLBENCH_IDS_FILE="$ids_file" \
    PYTHONDONTWRITEBYTECODE=1 \
    ./python /tmp/lolbench_lane.py
  ) > "$results_file" 2> "$err_file"
}

run_lane "$P2P_EFFECTIVE" "$P2P_RESULTS_JSON" "$P2P_RUNNER_ERR"
p2p_runner_rc=$?
if [ "$p2p_runner_rc" -ne 0 ] || [ ! -s "$P2P_RESULTS_JSON" ]; then
  log "P2P test runner failed (rc=$p2p_runner_rc); tail of runner stderr:"
  tail -60 "$P2P_RUNNER_ERR" >&2 || true
fi

run_lane "$F2P_EFFECTIVE" "$F2P_RESULTS_JSON" "$F2P_RUNNER_ERR"
f2p_runner_rc=$?
if [ "$f2p_runner_rc" -ne 0 ] || [ ! -s "$F2P_RESULTS_JSON" ]; then
  log "F2P test runner failed (rc=$f2p_runner_rc); tail of runner stderr:"
  tail -60 "$F2P_RUNNER_ERR" >&2 || true
fi

cat > "$WS/.lane_rcs.json" <<EOF
{"f2p": $f2p_runner_rc, "p2p": $p2p_runner_rc}
EOF

# ---- Build the reports from the JSON the in-process runner emitted ---
python3 - "$F2P_RESULTS_JSON" "$P2P_RESULTS_JSON" "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$MODE" "$SUITE" "$WS/.lane_rcs.json" "$F2P_RUNNER_ERR" "$P2P_RUNNER_ERR" <<'PYEOF'
import json, sys
(
    f2p_results_path,
    p2p_results_path,
    f2p_file,
    p2p_file,
    mode,
    suite,
    lane_rcs_path,
    f2p_err_path,
    p2p_err_path,
) = sys.argv[1:10]

def ids(p): return [l.strip() for l in open(p) if l.strip()]
f2p_ids = ids(f2p_file); p2p_ids = ids(p2p_file)

def err_tail(path):
    try:
        with open(path, "r", errors="replace") as f:
            return f.read()[-1000:]
    except OSError:
        return ""

def fallback(ids_, lane, rc, err_path):
    msg = f"{lane}_runner_failed rc={rc}: {err_tail(err_path)}"[:2000]
    return (
        {"PASSED": [], "FAILED": [], "ERROR": list(ids_), "SKIPPED": []},
        {tid: {"verdict": "ERROR", "msg": msg} for tid in ids_},
    )

def read_lane(path, ids_, lane, rc, err_path):
    if rc != 0:
        return fallback(ids_, lane, rc, err_path)
    try:
        with open(path) as f:
            r = json.load(f)
        return r["results"], r["detail"]
    except Exception:
        return fallback(ids_, lane, rc, err_path)

lane_rcs = json.load(open(lane_rcs_path))
f2p, f2p_detail = read_lane(
    f2p_results_path, f2p_ids, "f2p", lane_rcs["f2p"], f2p_err_path
)
p2p, p2p_detail = read_lane(
    p2p_results_path, p2p_ids, "p2p", lane_rcs["p2p"], p2p_err_path
)

resolved = (len(f2p["PASSED"]) == len(f2p_ids)
            and len(p2p["PASSED"]) == len(p2p_ids))

INSTANCE = "CPython_PEP-654_Exception-Groups-and-except_PR-29581"
grader = {"instance_id": INSTANCE, "mode": mode, "suite": suite, "applied": True,
          "build": {"status": "ok"},
          "f2p": f2p, "f2p_detail": f2p_detail,
          "p2p": p2p, "p2p_detail": p2p_detail,
          "resolved": resolved}

def cnts(d, want):
    return {"passed": len(d["PASSED"]), "failed": len(d["FAILED"]),
            "errored": len(d["ERROR"]), "skipped": len(d["SKIPPED"]),
            "total": len(want)}
agent = {"instance_id": INSTANCE, "suite": suite, "applied": True,
         "build": {"status": "ok"},
         "f2p": cnts(f2p, f2p_ids),
         "p2p": cnts(p2p, p2p_ids),
         "resolved": resolved, "error_categories": []}
json.dump(grader, open("/opt/lolbench/private/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

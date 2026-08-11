#!/usr/bin/env bash
# LoLBench runner for CPython PR-22917 (PEP 634).
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
#       lolbench/cpython-pr-22917:1
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
  "instance_id": "CPython_PEP-634_Structural-Pattern-Matching_PR-22917",
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
allowed_sections = {
    "Abstract",
    "Syntax and Semantics",
    "Syntax and Semantics > Overview and Terminology",
    "Syntax and Semantics > The Match Statement",
    "Syntax and Semantics > The Match Statement > Match Semantics",
    "Syntax and Semantics > The Match Statement > Guards",
    "Syntax and Semantics > The Match Statement > Irrefutable case blocks",
    "Syntax and Semantics > Patterns",
    "Syntax and Semantics > Patterns > AS Patterns",
    "Syntax and Semantics > Patterns > OR Patterns",
    "Syntax and Semantics > Patterns > Literal Patterns",
    "Syntax and Semantics > Patterns > Capture Patterns",
    "Syntax and Semantics > Patterns > Wildcard Pattern",
    "Syntax and Semantics > Patterns > Value Patterns",
    "Syntax and Semantics > Patterns > Group Patterns",
    "Syntax and Semantics > Patterns > Sequence Patterns",
    "Syntax and Semantics > Patterns > Mapping Patterns",
    "Syntax and Semantics > Patterns > Class Patterns",
    "Side Effects and Undefined Behavior",
    "The Standard Library",
    "Appendix A -- Full Grammar",
    "Copyright",
}
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
        sections = entry.get("requirement_sections")
        ok = ok and bool(sections) and all(s in allowed_sections for s in sections) \
                and bool(entry.get("public_surface")) \
                and isinstance(entry.get("mutants_targeted"), list) \
                and bool(entry.get("rationale"))
    for tid in aug_p2p:
        entry = p2p_triage.get(tid, {})
        sections = entry.get("requirement_sections")
        ok = ok and bool(sections) and all(s in allowed_sections for s in sections) \
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
    if [ -f /solution/solution.patch ]; then
      SRC_PATCH=/solution/solution.patch
    else
      SRC_PATCH="$PRIV/solution.patch"
    fi ;;
  eval)
    if [ ! -f /in/solution.patch ]; then
      log "no /in/solution.patch mounted"
      emit_error missing_solution_patch false skipped
      exit 0
    fi
    AGENT_PATCH=/tmp/lolbench_agent_patch.diff
    cp /in/solution.patch "$AGENT_PATCH"
    chmod 0600 "$AGENT_PATCH"
    SRC_PATCH="$AGENT_PATCH" ;;
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
# only what's needed.  For PEP 634 solution.patch touches Grammar/python.gram,
# Parser/parser.c, Parser/Python.asdl + asdl_c.py, Python/compile.c, ceval.c,
# ast.c, symtable.c, the generated Python-ast.c/h, opcode.h/opcode_targets.h,
# plus 10 Objects/ files for __match_args__ slots.  configure-related
# changes (configure.ac, pyconfig.h.in) require a re-run, which we trigger
# when those files are in the patch.
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
# because test_patma.py uses match/case syntax that the old parser does
# not recognise (SyntaxError → ImportError → ERROR); and the few F2P
# tests from modified files fail because their bodies reference
# __match_args__ (added to built-in types by solution.patch) or
# new ast.Match* AST nodes — both AttributeError → ERROR (acceptable
# per §6.4).

RESULTS_JSON=$WS/.results.json
RUNNER_ERR=$WS/.runner.err
F2P_EFFECTIVE=$WS/.f2p_effective.txt
P2P_EFFECTIVE=$WS/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" > "$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" > "$P2P_EFFECTIVE"

# Emit the per-id runner as a one-shot Python script the freshly-built
# ./python will execute.  Using ./python (not the system python3)
# guarantees we are exercising the version we just built.
cat > /tmp/lolbench_aggregate.py <<'PYRUN'
"""Run F2P/P2P unittest ids one-by-one under the freshly-built ./python.

For each id:
  * unittest.TestLoader.loadTestsFromName(id) imports the module + class
    and resolves the leaf method.  Any SyntaxError (match/case not yet
    recognised at base_commit) or AttributeError (__match_args__ /
    ast.Match* absent) becomes a clean ERROR — exactly the pre-state
    behavior we want for F2P.
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


f2p_ids = load_ids(os.environ["LOLBENCH_F2P_FILE"])
p2p_ids = load_ids(os.environ["LOLBENCH_P2P_FILE"])
f2p, f2p_detail = aggregate(f2p_ids)
p2p, p2p_detail = aggregate(p2p_ids)
json.dump(
    {
        "f2p": f2p,
        "f2p_detail": f2p_detail,
        "p2p": p2p,
        "p2p_detail": p2p_detail,
    },
    sys.stdout,
)
sys.stdout.write("\n")
PYRUN

cat > /tmp/lolbench_run_one.py <<'PYONE'
"""Crash-isolating fallback runner for a single unittest id."""
import json
import sys
import unittest
from io import StringIO


def run_one(test_id):
    loader = unittest.TestLoader()
    try:
        suite = loader.loadTestsFromName(test_id)
    except Exception as exc:
        return "ERROR", f"load_failed: {type(exc).__name__}: {exc}"[:2000]
    n = suite.countTestCases()
    if n == 0:
        return "ERROR", "no_tests_collected"
    if n > 1:
        return "ERROR", f"ambiguous: {n} cases collected for one id"
    stream = StringIO()
    try:
        result = unittest.TextTestRunner(
            stream=stream, verbosity=0, buffer=False
        ).run(suite)
    except SystemExit as exc:
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
    return "PASSED", ""


tid = sys.argv[1]
verdict, msg = run_one(tid)
json.dump({"id": tid, "verdict": verdict, "msg": msg}, sys.stdout)
sys.stdout.write("\n")
PYONE

cat > /tmp/lolbench_append_isolated.py <<'PYAPPEND'
import json
import sys

mode = sys.argv[1]
if mode == "ok":
    lane, one_path = sys.argv[2:4]
    data = json.load(open(one_path))
else:
    lane, test_id, rc, err_path = sys.argv[2:6]
    try:
        err = open(err_path, errors="replace").read()[-2000:]
    except OSError:
        err = ""
    data = {
        "id": test_id,
        "verdict": "ERROR",
        "msg": f"process_failed rc={rc}: {err}"[-2000:],
    }
data["lane"] = lane
print(json.dumps(data))
PYAPPEND

run_isolated_lane() {
  local lane=$1 ids_file=$2 jsonl=$3
  local test_id one_out one_err rc
  while IFS= read -r test_id; do
    [ -n "$test_id" ] || continue
    one_out="$WS/.one_${lane}.json"
    one_err="$WS/.one_${lane}.err"
    (
      cd "$CPYTHON"
      PYTHONDONTWRITEBYTECODE=1 \
      ./python /tmp/lolbench_run_one.py "$test_id"
    ) >"$one_out" 2>"$one_err"
    rc=$?
    if [ "$rc" -eq 0 ] && [ -s "$one_out" ]; then
      python3 /tmp/lolbench_append_isolated.py ok "$lane" "$one_out" >>"$jsonl"
    else
      python3 /tmp/lolbench_append_isolated.py error "$lane" "$test_id" "$rc" "$one_err" >>"$jsonl"
    fi
  done < "$ids_file"
}

(
  cd "$CPYTHON"
  LOLBENCH_F2P_FILE="$F2P_EFFECTIVE" \
  LOLBENCH_P2P_FILE="$P2P_EFFECTIVE" \
  PYTHONDONTWRITEBYTECODE=1 \
  ./python /tmp/lolbench_aggregate.py
) > "$RESULTS_JSON" 2> "$RUNNER_ERR"
runner_rc=$?

if [ "$runner_rc" -ne 0 ] || [ ! -s "$RESULTS_JSON" ]; then
  log "test runner failed (rc=$runner_rc); tail of runner stderr:"
  tail -60 "$RUNNER_ERR" >&2 || true
  log "retrying selected tests one-by-one to isolate interpreter crashes"
  ISO_JSONL=$WS/.isolated_results.jsonl
  : > "$ISO_JSONL"
  run_isolated_lane f2p "$F2P_EFFECTIVE" "$ISO_JSONL"
  run_isolated_lane p2p "$P2P_EFFECTIVE" "$ISO_JSONL"
  if ! python3 - "$ISO_JSONL" > "$RESULTS_JSON" <<'PYISO'
import json
import sys

path = sys.argv[1]
out = {
    "f2p": {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []},
    "f2p_detail": {},
    "p2p": {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []},
    "p2p_detail": {},
}
seen = 0
with open(path) as f:
    for line in f:
        if not line.strip():
            continue
        seen += 1
        item = json.loads(line)
        lane = item["lane"]
        tid = item["id"]
        verdict = item["verdict"]
        msg = item.get("msg", "")
        bucket = out[lane]
        if verdict not in bucket:
            verdict = "ERROR"
        bucket[verdict].append(tid)
        out[f"{lane}_detail"][tid] = {"verdict": verdict, "msg": msg}
if seen == 0:
    raise SystemExit(1)
json.dump(out, sys.stdout)
sys.stdout.write("\n")
PYISO
  then
    log "isolated fallback failed"
    emit_error harness_error true ok
    exit 0
  fi
fi

# ---- Build the reports from the JSON the in-process runner emitted ---
python3 - "$RESULTS_JSON" "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$MODE" "$SUITE" <<'PYEOF'
import json, sys
results_path, f2p_file, p2p_file, mode, suite = sys.argv[1:6]

def ids(p): return [l.strip() for l in open(p) if l.strip()]
f2p_ids = ids(f2p_file); p2p_ids = ids(p2p_file)
r = json.load(open(results_path))
f2p, p2p = r["f2p"], r["p2p"]

resolved = (len(f2p["PASSED"]) == len(f2p_ids)
            and len(p2p["PASSED"]) == len(p2p_ids))

INSTANCE = "CPython_PEP-634_Structural-Pattern-Matching_PR-22917"
grader = {"instance_id": INSTANCE, "mode": mode, "suite": suite, "applied": True,
          "build": {"status": "ok"},
          "f2p": f2p, "f2p_detail": r["f2p_detail"],
          "p2p": p2p, "p2p_detail": r["p2p_detail"],
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
json.dump(grader, open("/out/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

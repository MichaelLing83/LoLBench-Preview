#!/usr/bin/env bash
# LoLBench runner for FastAPI PR-4871 (PEP-593 Annotated dependency support).
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
FASTAPI=$WS/fastapi
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}
INSTANCE_ID="FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871"

case "$SUITE" in
  orig|aug|union) ;;
  *) echo "[run_tests $MODE/$SUITE] FATAL: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi
if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    echo "[run_tests $MODE/$SUITE] WARN: sidecar files missing; falling back to orig" >&2
    SUITE=orig
fi

FAIL_TO_PASS=()
PASS_TO_PASS=()

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }
die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

emit_error() {
    local cat=$1 applied=$2 build_status=$3
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$INSTANCE_ID" "$SUITE" "$HAS_AUG" <<'EOF' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, iid, suite, has_aug = sys.argv[1:9]
print(json.dumps({
  "instance_id": iid,
  "suite": suite,
  "augmentation_available": has_aug == "1",
  "applied": applied_s.lower() == "true",
  "build": {"status": build_s},
  "f2p": {"passed":0,"failed":0,"errored":int(f2p_n),"skipped":0,"total":int(f2p_n)},
  "p2p": {"passed":0,"failed":0,"errored":int(p2p_n),"skipped":0,"total":int(p2p_n)},
  "resolved": False, "error_categories": [cat]
}, indent=2))
EOF
}

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
    mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" \
         "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" "$HAS_AUG" <<'EOF' || die "spec/selector mismatch"
import json, sys
spec_path, f2p_path, p2p_path, f2p_aug_path, p2p_aug_path, has_aug = sys.argv[1:7]
spec = json.load(open(spec_path))
def ids(path):
    try:
        return [l.strip() for l in open(path) if l.strip()]
    except FileNotFoundError:
        return []
f2p = ids(f2p_path)
p2p = ids(p2p_path)
f2p_aug = ids(f2p_aug_path)
p2p_aug = ids(p2p_aug_path)
allowed_sections = {
    "Abstract",
    "Motivation",
    "Rationale",
    "Motivating examples",
    "Combining runtime and static uses of annotations",
    "Lowering barriers to developing new typing constructs",
    "Specification",
    "Specification > Syntax",
    "Specification > Consuming annotations",
    "Interaction with ``get_type_hints()``",
    "Aliases & Concerns over verbosity",
    "Rejected ideas",
    "Copyright",
}
ok = spec["fail_to_pass"] == f2p and spec["pass_to_pass"] == p2p
if has_aug == "1":
    aug = spec.get("augmented", {})
    triage = aug.get("triage", {})
    ok = ok and aug.get("fail_to_pass") == f2p_aug
    ok = ok and aug.get("pass_to_pass") == p2p_aug
    ok = ok and set(triage.get("fail_to_pass", {})) == set(f2p_aug)
    ok = ok and set(triage.get("pass_to_pass", {})) == set(p2p_aug)
    ok = ok and isinstance(triage.get("test_level_policy"), str) and triage.get("test_level_policy").strip()
    for entry in triage.get("fail_to_pass", {}).values():
        sections = entry.get("requirement_sections")
        ok = ok and isinstance(sections, list) and bool(sections)
        ok = ok and set(sections or []) <= allowed_sections
        ok = ok and isinstance(entry.get("public_surface"), str) and entry.get("public_surface").strip()
        ok = ok and isinstance(entry.get("mutants_targeted"), list)
        ok = ok and isinstance(entry.get("rationale"), str) and entry.get("rationale").strip()
    for entry in triage.get("pass_to_pass", {}).values():
        sections = entry.get("requirement_sections")
        ok = ok and isinstance(sections, list) and bool(sections)
        ok = ok and set(sections or []) <= allowed_sections
        ok = ok and isinstance(entry.get("public_surface"), str) and entry.get("public_surface").strip()
        ok = ok and isinstance(entry.get("rationale"), str) and entry.get("rationale").strip()
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

SRC_PATCH=""
case "$MODE" in
  validate_pre)  SRC_PATCH="" ;;
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
  *) die "unknown LOLBENCH_MODE=$MODE" ;;
esac

cd "$FASTAPI"
git config --global --add safe.directory "$FASTAPI"
git reset --hard >/dev/null 2>&1

if [ -n "$SRC_PATCH" ]; then
  if ! git apply --check "$SRC_PATCH" 2>/tmp/apply.err; then
    log "source patch did not apply cleanly:"; cat /tmp/apply.err >&2
    emit_error patch_apply_failure false skipped; exit 0
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
  log "eval_tests.patch did not apply cleanly:"; cat /tmp/apply.err >&2
  emit_error eval_patch_apply_failure true skipped; exit 0
fi
git apply "$PRIV/eval_tests.patch"

if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
  if ! git apply --check "$PRIV/eval_tests_aug.patch" 2>/tmp/apply.err; then
    log "eval_tests_aug.patch did not apply cleanly:"; cat /tmp/apply.err >&2
    emit_error eval_aug_patch_apply_failure true skipped; exit 0
  fi
  git apply "$PRIV/eval_tests_aug.patch"
fi

# Reinstall fastapi (editable) so the source patch changes take effect.
pip install -e . >/tmp/install.log 2>&1 || true

F2P_REPORT=$WS/.f2p_report.json
P2P_REPORT=$WS/.p2p_report.json
: >"$F2P_REPORT" >"$P2P_REPORT"

# F2P + P2P are run in SEPARATE pytest invocations to avoid pre-state
# collection failures in NEW test files (which import fixture apps using
# new public API) bleeding into P2P (untouched neighbor tests).
TEST_LOG=$WS/.pytest.log
: >"$TEST_LOG"
F2P_EFFECTIVE=$WS/.f2p_effective.txt
P2P_EFFECTIVE=$WS/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" >"$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" >"$P2P_EFFECTIVE"
log "running ${#FAIL_TO_PASS[@]} F2P tests under pytest"
PYTHONPATH=. python -m pytest "${FAIL_TO_PASS[@]}" \
    --tb=short -p no:cacheprovider \
    --json-report --json-report-file="$F2P_REPORT" \
    >>"$TEST_LOG" 2>&1 || true
log "running ${#PASS_TO_PASS[@]} P2P tests under pytest"
PYTHONPATH=. python -m pytest "${PASS_TO_PASS[@]}" \
    --tb=short -p no:cacheprovider \
    --json-report --json-report-file="$P2P_REPORT" \
    >>"$TEST_LOG" 2>&1 || true

REPORT="$F2P_REPORT $P2P_REPORT"

# Aggregate results
python3 - "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$F2P_REPORT" "$P2P_REPORT" "$MODE" "$INSTANCE_ID" "$SUITE" "$HAS_AUG" <<'PYEOF'
import json, sys, re, os

f2p_file, p2p_file, f2p_report, p2p_report, mode, iid, suite, has_aug = sys.argv[1:9]
f2p_ids = [l.strip() for l in open(f2p_file) if l.strip()]
p2p_ids = [l.strip() for l in open(p2p_file) if l.strip()]

def base_id(nid):
    return nid.split("[")[0]

results = {}
def parse(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return
    try:
        r = json.load(open(path))
    except Exception as e:
        print(f"WARN: could not parse {path}: {e}", file=sys.stderr)
        return
    # If pytest failed to collect tests, collectors list reports it.
    for c in r.get("collectors", []):
        if c.get("outcome") == "failed":
            nid = c.get("nodeid","")
            # collection errors → assign ERROR to every selector under that file
            bid = base_id(nid)
            results.setdefault(bid, []).append("ERROR")
    for t in r.get("tests", []):
        nid = t.get("nodeid","")
        outcome = t.get("outcome","")
        bid = base_id(nid)
        st = {"passed":"PASSED","failed":"FAILED","error":"ERROR","skipped":"SKIPPED"}.get(outcome, "ERROR")
        results.setdefault(bid, []).append(st)
parse(f2p_report)
parse(p2p_report)

def verdict_for(spec_id):
    sts = results.get(spec_id, [])
    if not sts:
        return "ERROR"
    if any(s == "FAILED" for s in sts): return "FAILED"
    if any(s == "ERROR" for s in sts): return "ERROR"
    # Strict no-skip aggregation: any SKIPPED variant → SKIPPED (never collapse to PASSED).
    if any(s == "SKIPPED" for s in sts) and not any(s == "PASSED" for s in sts):
        return "SKIPPED"
    if any(s == "SKIPPED" for s in sts):
        return "SKIPPED"
    return "PASSED"

def bucket(ids):
    out = {"PASSED":[],"FAILED":[],"ERROR":[],"SKIPPED":[]}
    detail = {}
    for i in ids:
        v = verdict_for(i)
        out[v].append(i)
        detail[i] = {"verdict": v}
    return out, detail

f2p, f2p_detail = bucket(f2p_ids)
p2p, p2p_detail = bucket(p2p_ids)
resolved = len(f2p["PASSED"]) == len(f2p_ids) and len(p2p["PASSED"]) == len(p2p_ids)

grader = {"instance_id":iid,"mode":mode,"suite":suite,"augmentation_available":has_aug == "1",
          "applied":True,"build":{"status":"ok"},
          "f2p":f2p,"f2p_detail":f2p_detail,
          "p2p":p2p,"p2p_detail":p2p_detail,
          "resolved":resolved}
def cnts(d, ids):
    return {"passed":len(d["PASSED"]),"failed":len(d["FAILED"]),
            "errored":len(d["ERROR"]),"skipped":len(d["SKIPPED"]),"total":len(ids)}
agent = {"instance_id":iid,"suite":suite,"augmentation_available":has_aug == "1",
         "applied":True,"build":{"status":"ok"},
         "f2p":cnts(f2p, f2p_ids),"p2p":cnts(p2p, p2p_ids),
         "resolved":resolved,"error_categories":[]}
json.dump(grader, open("/out/grader_report.json","w"), indent=2)
json.dump(agent, open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

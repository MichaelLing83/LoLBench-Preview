#!/usr/bin/env bash
# LoLBench runner for Apache-Kafka PR-7378 (KIP-470).
#
# F2P/P2P live in two modules — :streams:test-utils and :streams:examples
# — so we run :streams:test-utils:test and :streams:examples:test together.
#
# Eval contract:
#   docker run --rm \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/apache-kafka-kip-470-pr-7378:1
#
# Validation modes (bundle author):
#   LOLBENCH_MODE=validate_pre   F2P all ERROR + P2P all PASS
#   LOLBENCH_MODE=validate_post  all PASS
#   LOLBENCH_SUITE=orig|aug|union selects original, augmented, or combined tests.
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
KAFKA=$WS/kafka
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}
case "$SUITE" in
  orig|aug|union) ;;
  *) echo "[run_tests $MODE] FATAL: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 0 ;;
esac

# JUnit XML output dirs.
F2P_REPORT_DIRS=(
    "$KAFKA/streams/test-utils/build/test-results/test"
)
# P2P lives in :connect:json — an independent module untouched by either
# patch. This gives us strict §7 P2P PASS in pre-state without the
# monolithic-test-compile deviation that KIP-460 had to document.
P2P_REPORT_DIRS=(
    "$KAFKA/connect/json/build/test-results/test"
)

GRADLE_FLAGS=(
    --no-daemon
    -PscalaVersion=2.12
    -x rat
    -x checkstyleMain -x checkstyleTest
    -x spotbugsMain   -x spotbugsTest
)

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }
die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

emit_error() {
    local cat=$1 applied=$2 build_status=$3
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$SUITE" "${HAS_AUG:-0}" <<'EOF' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, suite, has_aug_s = sys.argv[1:8]
applied = applied_s.lower() == "true"
print(json.dumps({
  "instance_id": "Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378",
  "suite": suite,
  "augmentation_available": has_aug_s == "1",
  "applied": applied,
  "build": {"status": build_s},
  "f2p": {"passed":0,"failed":0,"errored":int(f2p_n),"skipped":0,"total":int(f2p_n)},
  "p2p": {"passed":0,"failed":0,"errored":int(p2p_n),"skipped":0,"total":int(p2p_n)},
  "resolved": False,
  "error_categories": [cat]
}, indent=2))
EOF
}

mapfile -t ORIG_F2P < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t ORIG_P2P < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS=("${ORIG_F2P[@]}")
PASS_TO_PASS=("${ORIG_P2P[@]}")

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] && [ -f "$PRIV/f2p_aug.txt" ] && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
    mapfile -t AUG_F2P < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t AUG_P2P < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
    case "$SUITE" in
      aug)
        FAIL_TO_PASS=("${AUG_F2P[@]}")
        PASS_TO_PASS=("${AUG_P2P[@]}")
        ;;
      union)
        FAIL_TO_PASS=("${ORIG_F2P[@]}" "${AUG_F2P[@]}")
        PASS_TO_PASS=("${ORIG_P2P[@]}" "${AUG_P2P[@]}")
        ;;
    esac
fi

SELECTED_F2P=/tmp/lolbench_kip470_f2p_selected.txt
SELECTED_P2P=/tmp/lolbench_kip470_p2p_selected.txt
printf "%s\n" "${FAIL_TO_PASS[@]}" > "$SELECTED_F2P"
printf "%s\n" "${PASS_TO_PASS[@]}" > "$SELECTED_P2P"

python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" "$HAS_AUG" <<'EOF' || die "spec/selector mismatch"
import json, sys
spec = json.load(open(sys.argv[1]))
f2p  = [l.strip() for l in open(sys.argv[2]) if l.strip()]
p2p  = [l.strip() for l in open(sys.argv[3]) if l.strip()]
has_aug = sys.argv[6] == "1"
if spec["fail_to_pass"] != f2p or spec["pass_to_pass"] != p2p:
    sys.exit(1)
if has_aug:
    f2p_aug = [l.strip() for l in open(sys.argv[4]) if l.strip()]
    p2p_aug = [l.strip() for l in open(sys.argv[5]) if l.strip()]
    aug = spec.get("augmented")
    if not aug or aug.get("fail_to_pass") != f2p_aug or aug.get("pass_to_pass") != p2p_aug:
        sys.exit(1)
    triage = aug.get("triage", {})
    if set(triage.get("fail_to_pass", {})) != set(f2p_aug):
        sys.exit(1)
    if set(triage.get("pass_to_pass", {})) != set(p2p_aug):
        sys.exit(1)
    for entry in triage.get("fail_to_pass", {}).values():
        if not entry.get("requirement_sections") or not entry.get("public_surface") or not entry.get("mutants_targeted") or not entry.get("rationale"):
            sys.exit(1)
    for entry in triage.get("pass_to_pass", {}).values():
        if not entry.get("requirement_sections") or not entry.get("public_surface") or not entry.get("rationale"):
            sys.exit(1)
sys.exit(0)
EOF

SRC_PATCH=""
case "$MODE" in
  validate_pre)  SRC_PATCH="" ;;
  validate_post) SRC_PATCH="$PRIV/solution.patch" ;;
  eval)
    if [ ! -f /in/solution.patch ]; then
      log "no /in/solution.patch mounted"
      emit_error missing_solution_patch false skipped
      exit 0
    fi
    cp /in/solution.patch "$PRIV/agent_patch.diff"
    SRC_PATCH="$PRIV/agent_patch.diff" ;;
  *) die "unknown LOLBENCH_MODE=$MODE" ;;
esac

cd "$KAFKA"
git config --global --add safe.directory "$KAFKA"
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

# Compile only main sources for the modules we'll test. Targets picked
# to avoid pulling configurations.runtime (which would drag in
# :clients:compileTestJava via the same Kafka-2.4 copyDependantLibs
# trap discovered for KIP-460).
BUILD_LOG=$WS/.build.log
TEST_LOG=$WS/.test.log
: >"$BUILD_LOG" >"$TEST_LOG"

cd "$KAFKA"
gradle "${GRADLE_FLAGS[@]}" \
    :clients:jar :streams:test-utils:classes :streams:examples:classes \
    :connect:json:classes \
    >"$BUILD_LOG" 2>&1
build_status=$?

if [ "$build_status" -ne 0 ]; then
  log "build failed (rc=$build_status); tail:"; tail -40 "$BUILD_LOG" >&2
  emit_error build_failure true failed; exit 0
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

make_selectors() {
    local file=$1
    python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(" ".join("--tests " + (cls + "." + m if m else cls)
                for cls, m in ((i.partition("#")[0], i.partition("#")[2]) for i in ids)))
' "$file"
}
F2P_SELECTOR=$(make_selectors "$SELECTED_F2P")
P2P_SELECTOR=$(make_selectors "$SELECTED_P2P")
log "F2P selector: $F2P_SELECTOR"
log "P2P selector: $P2P_SELECTOR"

for d in "${F2P_REPORT_DIRS[@]}" "${P2P_REPORT_DIRS[@]}"; do rm -rf "$d" 2>/dev/null; done

# Run F2P and P2P separately so an F2P compile/test failure never masks
# the independent :connect:json P2P stability signal.
log "running F2P"
gradle "${GRADLE_FLAGS[@]}" \
    :streams:test-utils:test \
    $F2P_SELECTOR \
    --rerun-tasks --continue \
    -Dorg.gradle.parallel=false \
    >"$TEST_LOG" 2>&1 || true

log "running P2P"
gradle "${GRADLE_FLAGS[@]}" \
    :connect:json:test \
    $P2P_SELECTOR \
    --rerun-tasks --continue \
    -Dorg.gradle.parallel=false \
    >>"$TEST_LOG" 2>&1 || true

export F2P_DIRS="${F2P_REPORT_DIRS[*]}"
export P2P_DIRS="${P2P_REPORT_DIRS[*]}"
export INSTANCE_ID="Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378"
export SUITE
export HAS_AUG
python3 - "$SELECTED_F2P" "$SELECTED_P2P" "$MODE" <<'PYEOF'
import json, os, re, sys, xml.etree.ElementTree as ET
f2p_file, p2p_file, mode = sys.argv[1:4]
f2p_dirs = os.environ['F2P_DIRS'].split()
p2p_dirs = os.environ['P2P_DIRS'].split()

def parse_dirs(dirs):
    out = {}
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for fn in os.listdir(d):
            if not (fn.startswith('TEST-') and fn.endswith('.xml')):
                continue
            try:
                root = ET.parse(os.path.join(d, fn)).getroot()
            except ET.ParseError:
                continue
            for tc in root.iter('testcase'):
                cls = tc.attrib.get('classname', '')
                name = tc.attrib.get('name', '')
                status = 'PASSED'
                for child in tc:
                    tag = child.tag.lower()
                    if tag == 'failure':   status = 'FAILED'
                    elif tag == 'error':   status = 'ERROR'
                    elif tag == 'skipped': status = 'SKIPPED' if status == 'PASSED' else status
                out.setdefault(cls, {})[name] = status
    return out

def status_of(spec_id, report):
    cls, _, method = spec_id.partition('#')
    cls_results = report.get(cls)
    if cls_results is None:
        return "ERROR"
    if not method:
        variants = list(cls_results.values())
        if not variants: return "ERROR"
        if any(v == "FAILED" for v in variants):  return "FAILED"
        if any(v == "ERROR" for v in variants):   return "ERROR"
        if any(v == "SKIPPED" for v in variants): return "SKIPPED"
        return "PASSED"
    variants = [v for k, v in cls_results.items()
                if k == method or re.match(re.escape(method) + r'(\[|\(.*\))', k)]
    if not variants: return "ERROR"
    if any(v == "FAILED" for v in variants):  return "FAILED"
    if any(v == "ERROR" for v in variants):   return "ERROR"
    if any(v == "SKIPPED" for v in variants): return "SKIPPED"
    return "PASSED"

f2p_ids = [l.strip() for l in open(f2p_file) if l.strip()]
p2p_ids = [l.strip() for l in open(p2p_file) if l.strip()]
f2p_report = parse_dirs(f2p_dirs)
p2p_report = parse_dirs(p2p_dirs)

def bucket(ids, report):
    out = {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []}
    for i in ids:
        out[status_of(i, report)].append(i)
    return out

f2p = bucket(f2p_ids, f2p_report)
p2p = bucket(p2p_ids, p2p_report)
resolved = (len(f2p["PASSED"]) == len(f2p_ids)
            and len(p2p["PASSED"]) == len(p2p_ids))

iid = os.environ["INSTANCE_ID"]
suite = os.environ.get("SUITE", "orig")
has_aug = os.environ.get("HAS_AUG") == "1"
grader = {"instance_id":iid, "mode":mode, "suite":suite, "augmentation_available":has_aug,
          "applied":True,"build":{"status":"ok"},
          "f2p":f2p,"p2p":p2p,"resolved":resolved}
def cnts(d, ids):
    return {"passed":len(d["PASSED"]),"failed":len(d["FAILED"]),
            "errored":len(d["ERROR"]),"skipped":len(d["SKIPPED"]),"total":len(ids)}
agent  = {"instance_id":iid, "suite":suite, "augmentation_available":has_aug,
          "applied":True,"build":{"status":"ok"},
          "f2p":cnts(f2p, f2p_ids),"p2p":cnts(p2p, p2p_ids),
          "resolved":resolved,"error_categories":[]}
json.dump(grader, open("/opt/lolbench/private/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

#!/usr/bin/env bash
# LoLBench runner for Apache-Flink PR-26567 (FLIP-498 AsyncTableFunction).
#
# F2P lives in flink-table-planner and exercises AsyncTableFunction
# correlate SQL flows. The eval tests reference new async-table public
# types and planner/runtime paths that do not exist pre-patch, so the
# pre-state F2P signal is a compile/runtime ERROR.
#
# P2P lives in flink-clients unchanged CLI/program tests and augmented
# CLI option parsing tests. P2P is compiled and run in its OWN Maven reactor
# (flink-clients only), separately from and before F2P, so the pre-state F2P
# test-compile failure in flink-table-planner cannot abort the P2P run. P2P
# therefore passes at both pre and post.
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
FLINK=$WS/flink
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}

INSTANCE_ID="Apache-Flink_FLIP-498_AsyncTableFunction-for-async-table-function-support_PR-26567"

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

F2P_MODULE="flink-table/flink-table-planner"
P2P_MODULE="flink-clients"
F2P_REPORT_DIR="$FLINK/$F2P_MODULE/target/surefire-reports"
P2P_REPORT_DIR="$FLINK/$P2P_MODULE/target/surefire-reports"
# P2P reports are copied here right after the P2P phase so they survive the
# subsequent (pre-state failing) F2P phase.
P2P_SAVED_REPORT_DIR="$WS/.p2p-surefire-reports"

MVN_OPTS_BASE=(
    "-B" "-fae" "-o"
    "-DskipITs"
    "-Dfast"
    "-Drat.skip=true"
    "-Dcheckstyle.skip=true"
    "-Dspotbugs.skip=true"
    "-Dspotless.check.skip=true"
    "-Dsurefire.failIfNoSpecifiedTests=false"
    "-Djapicmp.skip=true"
    "-Dscalastyle.skip=true"
    # No -am, offline (-o): use the pre-installed shaded jars from /root/.m2
    # (flink-table-code-splitter, flink-shaded-jsonpath etc.) instead of
    # building dependent modules. -pl is supplied PER PHASE so P2P runs in its
    # own reactor, isolated from a pre-state F2P test-compile failure.
)

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }
# Flink batch ITCase calls InetAddress.getLocalHost(); --network=none means
# the container's auto-hostname doesn't resolve.  Pre-seed /etc/hosts.
HOSTNAME_SELF=$(hostname 2>/dev/null || true)
if [ -n "$HOSTNAME_SELF" ] && ! grep -q "$HOSTNAME_SELF" /etc/hosts; then
    echo "127.0.0.1 $HOSTNAME_SELF" >> /etc/hosts
fi

die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

emit_error() {
    local cat=$1 applied=$2 build_status=$3
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$INSTANCE_ID" "$SUITE" "$HAS_AUG" <<'EOF' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, iid, suite, has_aug = sys.argv[1:9]
applied = applied_s.lower() == "true"
print(json.dumps({
  "instance_id": iid,
  "suite": suite,
  "augmentation_available": has_aug == "1",
  "applied": applied,
  "build": {"status": build_s},
  "f2p": {"passed":0,"failed":0,"errored":int(f2p_n),"skipped":0,"total":int(f2p_n)},
  "p2p": {"passed":0,"failed":0,"errored":int(p2p_n),"skipped":0,"total":int(p2p_n)},
  "resolved": False,
  "error_categories": [cat]
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
spec = json.load(open(sys.argv[1]))
def ids(path):
    try:
        return [l.strip() for l in open(path) if l.strip()]
    except FileNotFoundError:
        return []
orig_f2p = ids(sys.argv[2])
orig_p2p = ids(sys.argv[3])
ok = spec["fail_to_pass"] == orig_f2p and spec["pass_to_pass"] == orig_p2p
allowed_sections = {
    "FLIP-498: AsyncTableFunction for async table function support",
    "Motivation",
    "Scope",
    "Public Interfaces",
    "Proposed Changes",
    "Proposed Changes > Planner Changes",
    "Proposed Changes > Planner Changes > Split Rules",
    "Proposed Changes > Planner Changes > Physical Rules",
    "Proposed Changes > Runtime Changes",
    "Proposed Changes > Runtime Changes > Code Generation",
    "Proposed Changes > Runtime Changes > Operator",
    "Compatibility, Deprecation, and Migration Plan",
    "Test Plan",
    "Rejected Alternatives",
}
if sys.argv[6] == "1":
    aug = spec.get("augmented", {})
    aug_f2p = ids(sys.argv[4])
    aug_p2p = ids(sys.argv[5])
    triage = aug.get("triage", {})
    f2p_triage = triage.get("fail_to_pass", {})
    p2p_triage = triage.get("pass_to_pass", {})
    ok = ok and aug.get("fail_to_pass") == aug_f2p \
            and aug.get("pass_to_pass") == aug_p2p \
            and set(f2p_triage) == set(aug_f2p) \
            and set(p2p_triage) == set(aug_p2p) \
            and bool(triage.get("test_level_policy", "").strip())
    for tid in aug_f2p:
        entry = f2p_triage.get(tid, {})
        sections = entry.get("requirement_sections")
        ok = ok and bool(sections) and all(s in allowed_sections for s in sections) \
                and bool(entry.get("public_surface", "").strip()) \
                and isinstance(entry.get("mutants_targeted"), list) \
                and bool(entry.get("rationale", "").strip())
    for tid in aug_p2p:
        entry = p2p_triage.get(tid, {})
        sections = entry.get("requirement_sections")
        ok = ok and bool(sections) and all(s in allowed_sections for s in sections) \
                and bool(entry.get("public_surface", "").strip()) \
                and bool(entry.get("rationale", "").strip())
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

F2P_EFFECTIVE="/tmp/lolbench_f2p_effective.txt"
P2P_EFFECTIVE="/tmp/lolbench_p2p_effective.txt"
printf "%s\n" "${FAIL_TO_PASS[@]}" > "$F2P_EFFECTIVE"
printf "%s\n" "${PASS_TO_PASS[@]}" > "$P2P_EFFECTIVE"

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

cd "$FLINK"
git config --global --add safe.directory "$FLINK"
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

TEST_LOG=$WS/.test.log
: >"$TEST_LOG"

make_test_arg() {
    local ids_file=$1
    python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(",".join(i.replace("#","#") for i in ids))
' "$ids_file"
}

F2P_TESTS=$(make_test_arg "$F2P_EFFECTIVE")
P2P_TESTS=$(make_test_arg "$P2P_EFFECTIVE")
log "F2P tests: $F2P_TESTS"
log "P2P tests: $P2P_TESTS"

rm -rf "$F2P_REPORT_DIR" "$P2P_REPORT_DIR" "$P2P_SAVED_REPORT_DIR" 2>/dev/null

# Phase 1: install patched modules into ~/.m2 so the dep classpath at test
# time gets the SHADED jars (which bundle flink-table-code-splitter). Test
# compilation is DISABLED here (-Dmaven.test.skip=true) so the pre-state F2P
# test sources (which reference solution-only symbols) are NOT compiled at
# this step: install builds production code only and succeeds at pre and post.
log "phase 1: mvn install patched modules + deps (test compilation disabled)"
mvn -B -fae -o -Dmaven.test.skip=true -Dfast \
    -Drat.skip=true -Dcheckstyle.skip=true \
    -Dspotbugs.skip=true -Dspotless.check.skip=true \
    -Dmaven.javadoc.skip=true -Denforcer.skip=true -Djapicmp.skip=true \
    -pl "$F2P_MODULE,$P2P_MODULE" -am install \
    >"$TEST_LOG" 2>&1
inst_rc=$?
if [ "$inst_rc" -ne 0 ]; then
    log "production install failed (rc=$inst_rc)"
    tail -40 "$TEST_LOG" >&2
    emit_error build_failure true failed; exit 0
fi

# Phase 2a: run P2P selectors in their OWN reactor (flink-clients only) and
# save the reports immediately. flink-clients compiles independently of
# flink-table-planner, so a pre-state F2P test-compile failure cannot abort
# this run — P2P passes at both pre and post.
log "phase 2a: mvn test P2P selectors (flink-clients only)"
mvn "${MVN_OPTS_BASE[@]}" \
    -pl "$P2P_MODULE" \
    -Dtest="$P2P_TESTS" \
    test >>"$TEST_LOG" 2>&1 || true
mkdir -p "$P2P_SAVED_REPORT_DIR"
cp -R "$P2P_REPORT_DIR"/. "$P2P_SAVED_REPORT_DIR"/ 2>/dev/null || true

# Phase 2b: run F2P selectors in their OWN reactor (flink-table-planner only).
# At pre the eval F2P test sources reference solution-only symbols and fail to
# compile — that is the expected F2P signal, and it no longer touches the
# already-saved P2P results.
log "phase 2b: mvn test F2P selectors (flink-table-planner only)"
mvn "${MVN_OPTS_BASE[@]}" \
    -pl "$F2P_MODULE" \
    -Dtest="$F2P_TESTS" \
    test >>"$TEST_LOG" 2>&1 || true

export F2P_DIR="$F2P_REPORT_DIR" P2P_DIR="$P2P_SAVED_REPORT_DIR" INSTANCE_ID
python3 - "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$MODE" "$SUITE" "$HAS_AUG" <<'PYEOF'
import json, os, re, sys, xml.etree.ElementTree as ET
f2p_file, p2p_file, mode, suite, has_aug = sys.argv[1:6]
f2p_dir = os.environ['F2P_DIR']
p2p_dir = os.environ['P2P_DIR']
iid = os.environ['INSTANCE_ID']

def parse_dir(d):
    out = {}
    if not os.path.isdir(d): return out
    for fn in os.listdir(d):
        if not (fn.startswith('TEST-') and fn.endswith('.xml')): continue
        try: root = ET.parse(os.path.join(d, fn)).getroot()
        except ET.ParseError: continue
        for tc in root.iter('testcase'):
            cls = tc.attrib.get('classname', '')
            name = tc.attrib.get('name', '')
            status = 'PASSED'
            for ch in tc:
                tag = ch.tag.lower()
                if tag == 'failure': status = 'FAILED'
                elif tag == 'error': status = 'ERROR'
                elif tag == 'skipped': status = 'SKIPPED' if status == 'PASSED' else status
            out.setdefault(cls, {})[name] = status
    return out

def status_of(spec_id, report):
    cls, _, method = spec_id.partition('#')
    cls_results = report.get(cls)
    if cls_results is None: return "ERROR"
    if not method:
        variants = list(cls_results.values())
        if not variants: return "ERROR"
        for s in ("FAILED","ERROR","SKIPPED","PASSED"):
            if s in variants: return s
        return "PASSED"
    variants = [v for k,v in cls_results.items()
                if k == method or re.match(re.escape(method) + r'(\[|\(.*\))', k)]
    if not variants: return "ERROR"
    for s in ("FAILED","ERROR","SKIPPED","PASSED"):
        if s in variants: return s
    return "PASSED"

f2p_ids = [l.strip() for l in open(f2p_file) if l.strip()]
p2p_ids = [l.strip() for l in open(p2p_file) if l.strip()]
f2p_report = parse_dir(f2p_dir)
p2p_report = parse_dir(p2p_dir)

def bucket(ids, report):
    out = {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []}
    for i in ids: out[status_of(i, report)].append(i)
    return out

f2p = bucket(f2p_ids, f2p_report)
p2p = bucket(p2p_ids, p2p_report)
resolved = (len(f2p["PASSED"]) == len(f2p_ids)
            and len(p2p["PASSED"]) == len(p2p_ids))

grader = {"instance_id":iid, "mode":mode, "suite":suite, "augmentation_available":has_aug == "1",
          "applied":True, "build":{"status":"ok"},
          "f2p":f2p, "p2p":p2p, "resolved":resolved}
def cnts(d, ids):
    return {"passed":len(d["PASSED"]),"failed":len(d["FAILED"]),
            "errored":len(d["ERROR"]),"skipped":len(d["SKIPPED"]),"total":len(ids)}
agent = {"instance_id":iid, "suite":suite, "augmentation_available":has_aug == "1",
         "applied":True, "build":{"status":"ok"},
         "f2p":cnts(f2p, f2p_ids), "p2p":cnts(p2p, p2p_ids),
         "resolved":resolved, "error_categories":[]}
json.dump(grader, open("/out/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

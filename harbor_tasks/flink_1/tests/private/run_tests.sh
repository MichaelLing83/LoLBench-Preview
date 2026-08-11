#!/usr/bin/env bash
# LoLBench runner for Apache-Flink PR-9976 (FLIP-77).
#
# Eval contract (the only one agents need to know):
#   docker run --rm \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/apache-flink-flip-77-pr-9976:1
#   → /out/agent_report.json (sanitized).
#
# Validation modes (used by the benchmark builders only):
#   LOLBENCH_MODE=validate_pre   # F2P test-compile fails post-eval-patch
#                                # (new methods don't exist), P2P passes.
#   LOLBENCH_MODE=validate_post  # all PASS.
#
# All commands run as root (the eval container is invoked only by a
# trusted evaluator; agents never execute code inside it).
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
FLINK=$WS/flink
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

F2P_MODULES="flink-core"
P2P_MODULES="flink-clients"

# Per-module surefire-reports dirs (relative to $FLINK).
F2P_REPORT_DIRS=(
    "$FLINK/flink-core/target/surefire-reports"
)
P2P_REPORT_DIRS=(
    "$FLINK/flink-clients/target/surefire-reports"
)

MAVEN_FLAGS=(
    -B -fae
    -Drat.skip=true
    -Dcheckstyle.skip=true
    -Dmaven.javadoc.skip=true
    -Denforcer.skip=true
)

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }
die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

FAIL_TO_PASS=()
PASS_TO_PASS=()

# emit_error <category> <applied:true|false> <build_status>
emit_error() {
    local cat=$1 applied=$2 build_status=$3
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$SUITE" "$HAS_AUG" <<'EOF' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, suite, has_aug = sys.argv[1:8]
applied = applied_s.lower() == "true"
print(json.dumps({
  "instance_id": "Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976",
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

# Sanity-check spec ↔ selectors agree.
python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" \
         "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" "$HAS_AUG" <<'EOF' || die "spec/selector mismatch"
import json, sys
spec_path, f2p, p2p, f2p_aug, p2p_aug, has_aug = sys.argv[1:7]
spec = json.load(open(spec_path))
def ids(path): return [l.strip() for l in open(path) if l.strip()]
ok = spec["fail_to_pass"] == ids(f2p) and spec["pass_to_pass"] == ids(p2p)
if has_aug == "1":
    aug = spec.get("augmented", {})
    ok = ok and aug.get("fail_to_pass") == ids(f2p_aug) \
            and aug.get("pass_to_pass") == ids(p2p_aug)
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

# ---- pick source-side patch by mode ---------------------------------
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
  *)
    die "unknown LOLBENCH_MODE=$MODE" ;;
esac

# ---- reset workspace + apply source-side patch ----------------------
# Apply solution.patch BEFORE building so install compiles against the
# patched main sources.  eval_tests.patch is applied AFTER the build
# so test-compile failures (in pre-state) do not abort install — they
# instead surface as missing Surefire reports → ERROR rows per F2P id.
cd "$FLINK"
git config --global --add safe.directory "$FLINK"
git reset --hard >/dev/null 2>&1
git clean -fdx -e target -e '*/target' >/dev/null 2>&1

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

# ---- build (incremental; test-compile runs but tests don't execute) -
BUILD_LOG=$WS/.build.log
F2P_LOG=$WS/.f2p.log
P2P_LOG=$WS/.p2p.log
: >"$BUILD_LOG" >"$F2P_LOG" >"$P2P_LOG"

cd "$FLINK"
mvn "${MAVEN_FLAGS[@]}" \
    -pl "$F2P_MODULES,$P2P_MODULES" \
    -am -DskipTests install >"$BUILD_LOG" 2>&1
build_status=$?

if [ "$build_status" -ne 0 ]; then
  log "build failed (rc=$build_status); tail:"; tail -30 "$BUILD_LOG" >&2
  emit_error build_failure true failed; exit 0
fi

# Now apply the test-side patch (must succeed; otherwise our F2P spec
# is unverifiable).  Per-module test-compile failures show up later as
# missing Surefire reports → ERROR rows.
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

F2P_EFFECTIVE=$WS/.f2p_effective.txt
P2P_EFFECTIVE=$WS/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" >"$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" >"$P2P_EFFECTIVE"

# ---- Compute Surefire -Dtest selectors from the spec selectors -------
# Selector format: "ClassA#m1+m2,ClassB,ClassC#m1" (per-method) or
# "ClassA,ClassB,ClassC" (class-only).  Surefire expects simple class
# names (not FQCNs).  Group methods per class.
#
# F2P uses class-level only.  Reason: Surefire 2.22.1's #method
# filter compares against JUnit's Description.getMethodName(), which
# for @RunWith(Parameterized.class) returns "methodName[N]" (the index
# suffix is part of the name).  Plain "#methodName" therefore matches
# nothing for parameterized classes and Surefire reports
# `Tests run: 0`.  All three new flink-core F2P classes
# (ConfigurationConversionsTest, ConfigurationParsingInvalidFormatsTest,
# ReadableWritableConfigurationTest) are parameterized.  Falling back
# to class-level runs every @Test in the class; the downstream parser
# (status_of) still maps results back to method-level spec entries via
# the testcase XML's name attribute and its `method[N]` variants.
#
# P2P keeps the per-method selector because all flink-clients P2P
# entries are non-parameterized and we intentionally subset methods.
make_selector_method() {
    local file=$1
    python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
by_class = {}
for i in ids:
    cls, _, m = i.partition("#")
    by_class.setdefault(cls, []).append(m)
parts = []
for cls, ms in by_class.items():
    simple = cls.rsplit(".", 1)[1]
    if not ms or all(not m for m in ms):
        parts.append(simple)
    else:
        parts.append(simple + "#" + "+".join(filter(None, ms)))
print(",".join(parts))
' "$file"
}
make_selector_class() {
    local file=$1
    python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
classes = []
for i in ids:
    cls = i.partition("#")[0].rsplit(".", 1)[1]
    if cls not in classes:
        classes.append(cls)
print(",".join(classes))
' "$file"
}
F2P_SELECTOR=$(make_selector_class  "$F2P_EFFECTIVE")
P2P_SELECTOR=$(make_selector_method "$P2P_EFFECTIVE")
log "F2P selector: $F2P_SELECTOR"
log "P2P selector: $P2P_SELECTOR"

# Wipe surefire-reports from prior runs.
for d in "${F2P_REPORT_DIRS[@]}" "${P2P_REPORT_DIRS[@]}"; do rm -rf "$d" 2>/dev/null; done

# ---- F2P (single module here, but -fae kept for parity with FLIP-335)
mvn "${MAVEN_FLAGS[@]}" -pl "$F2P_MODULES" test \
    -Dtest="$F2P_SELECTOR" \
    -DfailIfNoTests=false \
    -Dsurefire.failIfNoSpecifiedTests=false \
    >"$F2P_LOG" 2>&1 || true

# ---- P2P (clean module — same patch state, just no compile issues) ---
mvn "${MAVEN_FLAGS[@]}" -pl "$P2P_MODULES" test \
    -Dtest="$P2P_SELECTOR" \
    -DfailIfNoTests=false \
    -Dsurefire.failIfNoSpecifiedTests=false \
    >"$P2P_LOG" 2>&1 || true

# ---- parse Surefire XML + emit reports ------------------------------
export F2P_DIRS="${F2P_REPORT_DIRS[*]}"
export P2P_DIRS="${P2P_REPORT_DIRS[*]}"
python3 - "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$MODE" "$SUITE" "$HAS_AUG" <<'PYEOF'
"""Parse Surefire XML reports across multiple module dirs."""
import json, os, sys, re, xml.etree.ElementTree as ET
f2p_file, p2p_file, mode, suite, has_aug = sys.argv[1:6]
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
                if k == method or re.match(re.escape(method) + r'\[', k)]
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

grader = {"instance_id":"Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976",
          "mode":mode,"suite":suite,"augmentation_available":has_aug == "1",
          "applied":True,"build":{"status":"ok"},
          "f2p":f2p,"p2p":p2p,"resolved":resolved}
def cnts(d, ids):
    return {"passed":len(d["PASSED"]),"failed":len(d["FAILED"]),
            "errored":len(d["ERROR"]),"skipped":len(d["SKIPPED"]),"total":len(ids)}
agent  = {"instance_id":"Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976",
          "suite":suite,"augmentation_available":has_aug == "1",
          "applied":True,"build":{"status":"ok"},
          "f2p":cnts(f2p, f2p_ids),"p2p":cnts(p2p, p2p_ids),
          "resolved":resolved,"error_categories":[]}
json.dump(grader, open("/out/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

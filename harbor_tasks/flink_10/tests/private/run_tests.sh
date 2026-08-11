#!/usr/bin/env bash
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
FLINK=$WS/flink
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}
INSTANCE_ID="Apache-Flink_FLIP-501-Support-Window-Extension-in-DataStream-V2-API_PR-26001"

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

F2P_MODULE="flink-tests"
P2P_MODULE="flink-clients"
F2P_REPORT_DIRS=(
  "$FLINK/$F2P_MODULE/target/surefire-reports"
  "$FLINK/$F2P_MODULE/target/failsafe-reports"
)
P2P_REPORT_DIR="$FLINK/$P2P_MODULE/target/surefire-reports"
P2P_SAVED_REPORT_DIR="$WS/.p2p-surefire-reports"

MAVEN_FLAGS=(
  -B -fae -o
  -Dfast
  -Drat.skip=true
  -Dcheckstyle.skip=true
  -Dspotbugs.skip=true
  -Dspotless.check.skip=true
  -Dmaven.javadoc.skip=true
  -Denforcer.skip=true
  -Djapicmp.skip=true
  -Dscalastyle.skip=true
  -Dsurefire.failIfNoSpecifiedTests=false
)
MAVEN_TEST_TIMEOUT_S=${MAVEN_TEST_TIMEOUT_S:-600}

log() { echo "[run_tests $MODE/$SUITE] $*" >&2; }

run_test_cmd() {
  local timeout_s=$1
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout --kill-after=30s "$timeout_s" "$@"
  else
    "$@"
  fi
}

FAIL_TO_PASS=()
PASS_TO_PASS=()

emit_error() {
  local cat=$1 applied=$2 build_status=$3
  local f2p_n=${#FAIL_TO_PASS[@]}
  local p2p_n=${#PASS_TO_PASS[@]}
  python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$INSTANCE_ID" "$SUITE" "$HAS_AUG" <<'PY' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, iid, suite, has_aug = sys.argv[1:9]
print(json.dumps({
  "instance_id": iid,
  "suite": suite,
  "augmentation_available": has_aug == "1",
  "applied": applied_s.lower() == "true",
  "build": {"status": build_s},
  "f2p": {"passed": 0, "failed": 0, "errored": int(f2p_n), "skipped": 0, "total": int(f2p_n)},
  "p2p": {"passed": 0, "failed": 0, "errored": int(p2p_n), "skipped": 0, "total": int(p2p_n)},
  "resolved": False,
  "error_categories": [cat],
}, indent=2))
PY
}

die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

HOSTNAME_SELF=$(hostname 2>/dev/null || true)
if [ -n "$HOSTNAME_SELF" ] && ! grep -q "$HOSTNAME_SELF" /etc/hosts; then
  echo "127.0.0.1 $HOSTNAME_SELF" >> /etc/hosts
fi

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
  mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
  mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" \
          "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" "$HAS_AUG" <<'PY' || die "spec/selector mismatch"
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
    "FLIP-501: Support Window Extension in DataStream V2 API",
    "Background",
    "Example",
    "Proposed Changes",
    "Proposed Changes > Declare Window",
    "Proposed Changes > Define `WindowProcessFunction`",
    "Proposed Changes > Define `WindowProcessFunction` > Lifecycle Methods",
    "Proposed Changes > Define `WindowProcessFunction` > State",
    "Proposed Changes > Define `WindowProcessFunction` > Store and access all records of a window",
    "Proposed Changes > Build a ProcessFunction",
    "Compatibility, Deprecation, and Migration Plan",
    "Test Plan",
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
raise SystemExit(0 if ok else 1)
PY

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
  validate_pre) SRC_PATCH="" ;;
  validate_post)
    if [ -f /solution/solution.patch ]; then
      SRC_PATCH=/solution/solution.patch
    else
      SRC_PATCH="$PRIV/solution.patch"
    fi ;;
  eval)
    if [ ! -f /in/solution.patch ]; then
      emit_error missing_solution_patch false skipped
      exit 0
    fi
    AGENT_PATCH=/tmp/lolbench_agent_patch.diff
    cp /in/solution.patch "$AGENT_PATCH"
    chmod 0600 "$AGENT_PATCH"
    SRC_PATCH="$AGENT_PATCH"
    ;;
  *) die "unknown LOLBENCH_MODE=$MODE" ;;
esac

cd "$FLINK"
git config --global --add safe.directory "$FLINK"
git reset --hard >/dev/null 2>&1

if [ -n "$SRC_PATCH" ]; then
  if ! git apply --check "$SRC_PATCH" 2>/tmp/apply.err; then
    log "source patch did not apply cleanly:"; cat /tmp/apply.err >&2
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
  log "eval_tests.patch did not apply cleanly:"; cat /tmp/apply.err >&2
  emit_error eval_patch_apply_failure true skipped
  exit 0
fi
git apply "$PRIV/eval_tests.patch"

if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
  if ! git apply --check "$PRIV/eval_tests_aug.patch" 2>/tmp/apply.err; then
    log "eval_tests_aug.patch did not apply cleanly:"; cat /tmp/apply.err >&2
    emit_error eval_aug_patch_apply_failure true skipped
    exit 0
  fi
  git apply "$PRIV/eval_tests_aug.patch"
fi

make_test_arg() {
  python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(",".join(ids))
' "$1"
}

F2P_TESTS=$(make_test_arg "$F2P_EFFECTIVE")
P2P_TESTS=$(make_test_arg "$P2P_EFFECTIVE")
TEST_LOG=$WS/.test.log
: >"$TEST_LOG"
trap 'cp "$TEST_LOG" /out/maven.log 2>/dev/null || true' EXIT

log "production compile/install with test compilation disabled"
mvn "${MAVEN_FLAGS[@]}" \
  -Dmaven.test.skip=true \
  -pl "$F2P_MODULE,$P2P_MODULE" -am \
  install >"$TEST_LOG" 2>&1
build_rc=$?
if [ "$build_rc" -ne 0 ]; then
  tail -60 "$TEST_LOG" >&2
  emit_error build_failure true failed
  exit 0
fi

for d in "${F2P_REPORT_DIRS[@]}"; do rm -rf "$d" 2>/dev/null; done
rm -rf "$P2P_REPORT_DIR" "$P2P_SAVED_REPORT_DIR" 2>/dev/null

log "running P2P selectors"
run_test_cmd "$MAVEN_TEST_TIMEOUT_S" mvn "${MAVEN_FLAGS[@]}" \
  -pl "$P2P_MODULE" \
  -Dtest="$P2P_TESTS" \
  test >>"$TEST_LOG" 2>&1
p2p_rc=$?
if [ "$p2p_rc" -ne 0 ]; then
  log "P2P selectors exited with rc=$p2p_rc"
fi
mkdir -p "$P2P_SAVED_REPORT_DIR"
cp -R "$P2P_REPORT_DIR"/. "$P2P_SAVED_REPORT_DIR"/ 2>/dev/null || true

log "running F2P selectors"
run_test_cmd "$MAVEN_TEST_TIMEOUT_S" mvn "${MAVEN_FLAGS[@]}" \
  -pl "$F2P_MODULE" \
  -Dtest="$F2P_TESTS" \
  "-Dit.test=$F2P_TESTS" \
  verify >>"$TEST_LOG" 2>&1
f2p_rc=$?
if [ "$f2p_rc" -ne 0 ]; then
  log "F2P selectors exited with rc=$f2p_rc"
fi

export F2P_DIRS="${F2P_REPORT_DIRS[*]}" P2P_DIR="$P2P_SAVED_REPORT_DIR" INSTANCE_ID
python3 - "$F2P_EFFECTIVE" "$P2P_EFFECTIVE" "$MODE" "$SUITE" "$HAS_AUG" <<'PY'
import json, os, re, sys, xml.etree.ElementTree as ET
f2p_file, p2p_file, mode, suite, has_aug = sys.argv[1:6]
f2p_dirs = os.environ["F2P_DIRS"].split()
p2p_dir = os.environ["P2P_DIR"]
iid = os.environ["INSTANCE_ID"]

def parse_dirs(dirs):
    out = {}
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for fn in os.listdir(d):
            if not (fn.startswith("TEST-") and fn.endswith(".xml")):
                continue
            try:
                root = ET.parse(os.path.join(d, fn)).getroot()
            except ET.ParseError:
                continue
            for tc in root.iter("testcase"):
                cls = tc.attrib.get("classname", "")
                name = tc.attrib.get("name", "")
                status = "PASSED"
                for ch in tc:
                    tag = ch.tag.lower()
                    if tag == "failure":
                        status = "FAILED"
                    elif tag == "error":
                        status = "ERROR"
                    elif tag == "skipped" and status == "PASSED":
                        status = "SKIPPED"
                out.setdefault(cls, {})[name] = status
    return out

def status_of(spec_id, report):
    cls, _, method = spec_id.partition("#")
    cls_results = report.get(cls)
    if cls_results is None:
        return "ERROR"
    if not method:
        variants = list(cls_results.values())
    else:
        variants = [
            v for k, v in cls_results.items()
            if k == method or re.match(re.escape(method) + r"(\[|\(.*\))", k)
        ]
    if not variants:
        return "ERROR"
    for s in ("FAILED", "ERROR", "SKIPPED", "PASSED"):
        if s in variants:
            return s
    return "PASSED"

f2p_ids = [l.strip() for l in open(f2p_file) if l.strip()]
p2p_ids = [l.strip() for l in open(p2p_file) if l.strip()]
f2p_report = parse_dirs(f2p_dirs)
p2p_report = parse_dirs([p2p_dir])

def bucket(ids, report):
    out = {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []}
    for i in ids:
        out[status_of(i, report)].append(i)
    return out

f2p = bucket(f2p_ids, f2p_report)
p2p = bucket(p2p_ids, p2p_report)
resolved = len(f2p["PASSED"]) == len(f2p_ids) and len(p2p["PASSED"]) == len(p2p_ids)

grader = {
    "instance_id": iid,
    "mode": mode,
    "suite": suite,
    "augmentation_available": has_aug == "1",
    "applied": True,
    "build": {"status": "ok"},
    "f2p": f2p,
    "p2p": p2p,
    "resolved": resolved,
}

def counts(d, ids):
    return {
        "passed": len(d["PASSED"]),
        "failed": len(d["FAILED"]),
        "errored": len(d["ERROR"]),
        "skipped": len(d["SKIPPED"]),
        "total": len(ids),
    }

agent = {
    "instance_id": iid,
    "suite": suite,
    "augmentation_available": has_aug == "1",
    "applied": True,
    "build": {"status": "ok"},
    "f2p": counts(f2p, f2p_ids),
    "p2p": counts(p2p, p2p_ids),
    "resolved": resolved,
    "error_categories": [],
}
json.dump(grader, open("/out/grader_report.json", "w"), indent=2)
json.dump(agent, open("/out/agent_report.json", "w"), indent=2)
print(json.dumps(grader, indent=2))
PY

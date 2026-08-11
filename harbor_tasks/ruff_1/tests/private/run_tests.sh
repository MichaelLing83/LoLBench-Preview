#!/usr/bin/env bash
# LoLBench runner for Ruff PR-9599 (Issue-8368 — CLI config overrides).
#
# F2P + P2P selectors are Rust integration tests under crates/ruff/tests/.
# Format: <test_file>::<test_name>  (matches cargo's `--test <file>` plus
# the bare function name).  Example:
#   format::config_override_via_cli
#   integration_test::stdin_success
#
# Strict §7: P2P selectors live in test binaries (integration_test.rs,
# show_settings.rs) untouched by eval_tests.patch, so they compile
# pre-state regardless of format/lint compile fate.  cargo test --test
# only compiles the named binary's deps, not the whole workspace, so
# the F2P fail-to-compile does not poison P2P binaries.
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
RUFF=$WS/ruff
MODE=${LOLBENCH_MODE:-eval}
SUITE=${LOLBENCH_SUITE:-orig}

INSTANCE_ID="Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599"

log() { echo "[run_tests $MODE] $*" >&2; }
die() { log "FATAL: $*"; emit_error harness_error false skipped; exit 0; }

emit_error() {
    local cat=$1 applied=$2 build_status=$3
    local f2p_n=${#FAIL_TO_PASS[@]}
    local p2p_n=${#PASS_TO_PASS[@]}
    python3 - "$cat" "$applied" "$build_status" "$f2p_n" "$p2p_n" "$INSTANCE_ID" <<'EOF' >/out/agent_report.json
import json, sys
cat, applied_s, build_s, f2p_n, p2p_n, iid = sys.argv[1:7]
applied = applied_s.lower() == "true"
print(json.dumps({
  "instance_id": iid,
  "applied": applied,
  "build": {"status": build_s},
  "f2p": {"passed":0,"failed":0,"errored":int(f2p_n),"skipped":0,"total":int(f2p_n)},
  "p2p": {"passed":0,"failed":0,"errored":int(p2p_n),"skipped":0,"total":int(p2p_n)},
  "resolved": False,
  "error_categories": [cat]
}, indent=2))
EOF
}

case "$SUITE" in
  orig|aug|union) ;;
  *) die "unknown LOLBENCH_SUITE=$SUITE" ;;
esac

read_selectors() {
    local kind=$1
    case "$SUITE:$kind" in
      orig:f2p)  grep -v '^\s*$' "$PRIV/f2p.txt" ;;
      orig:p2p)  grep -v '^\s*$' "$PRIV/p2p.txt" ;;
      aug:f2p)   grep -v '^\s*$' "$PRIV/f2p_aug.txt" ;;
      aug:p2p)   grep -v '^\s*$' "$PRIV/p2p_aug.txt" ;;
      union:f2p) cat "$PRIV/f2p.txt" "$PRIV/f2p_aug.txt" | grep -v '^\s*$' ;;
      union:p2p) cat "$PRIV/p2p.txt" "$PRIV/p2p_aug.txt" | grep -v '^\s*$' ;;
    esac
}

mapfile -t FAIL_TO_PASS < <(read_selectors f2p)
mapfile -t PASS_TO_PASS < <(read_selectors p2p)
printf "%s\n" "${FAIL_TO_PASS[@]}" > "$WS/f2p_effective.txt"
printf "%s\n" "${PASS_TO_PASS[@]}" > "$WS/p2p_effective.txt"

python3 - "$PRIV/spec.json" "$PRIV/f2p.txt" "$PRIV/p2p.txt" "$PRIV/f2p_aug.txt" "$PRIV/p2p_aug.txt" <<'EOF' || die "spec/selector mismatch"
import json, sys
spec = json.load(open(sys.argv[1]))
f2p  = [l.strip() for l in open(sys.argv[2]) if l.strip()]
p2p  = [l.strip() for l in open(sys.argv[3]) if l.strip()]
f2p_aug = [l.strip() for l in open(sys.argv[4]) if l.strip()]
p2p_aug = [l.strip() for l in open(sys.argv[5]) if l.strip()]
aug = spec.get("augmented", {})
triage = aug.get("triage", {})
allowed_sections = {
    "Allow override of configuration options via the CLI",
    "Allow override of configuration options via the CLI > Proposals",
}
ok = (
    spec["fail_to_pass"] == f2p
    and spec["pass_to_pass"] == p2p
    and aug.get("fail_to_pass") == f2p_aug
    and aug.get("pass_to_pass") == p2p_aug
    and set(triage.get("fail_to_pass", {})) == set(f2p_aug)
    and set(triage.get("pass_to_pass", {})) == set(p2p_aug)
)
for selector, entry in triage.get("fail_to_pass", {}).items():
    ok = ok and isinstance(entry.get("requirement_sections"), list)
    ok = ok and set(entry.get("requirement_sections", [])) <= allowed_sections
    ok = ok and isinstance(entry.get("public_surface"), str)
    ok = ok and isinstance(entry.get("mutants_targeted"), list)
    ok = ok and isinstance(entry.get("rationale"), str)
for selector, entry in triage.get("pass_to_pass", {}).items():
    ok = ok and isinstance(entry.get("requirement_sections"), list)
    ok = ok and set(entry.get("requirement_sections", [])) <= allowed_sections
    ok = ok and isinstance(entry.get("public_surface"), str)
    ok = ok and isinstance(entry.get("rationale"), str)
ok = ok and isinstance(triage.get("test_level_policy"), str)
sys.exit(0 if ok else 1)
EOF

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

cd "$RUFF"
git config --global --add safe.directory "$RUFF"
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

if [ "$SUITE" != "orig" ]; then
  if ! git apply --check "$PRIV/eval_tests_aug.patch" 2>/tmp/apply.err; then
    log "eval_tests_aug.patch did not apply cleanly:"; cat /tmp/apply.err >&2
    emit_error eval_patch_apply_failure true skipped; exit 0
  fi
  git apply "$PRIV/eval_tests_aug.patch"
fi

TEST_LOG=$WS/.test.log
: >"$TEST_LOG"

REPORTS_DIR=$WS/_reports
rm -rf "$REPORTS_DIR" && mkdir -p "$REPORTS_DIR/f2p" "$REPORTS_DIR/p2p"

run_one() {
    local sel=$1 outdir=$2
    local file=${sel%%::*}
    local name=${sel##*::}
    local jlog="$outdir/${file}_${name}.json"
    # Stable libtest uses plain output; cargo nightly + -Z unstable-options
    # gives JSON. Try human-readable first (works on stable 1.76).
    # `--exact` ensures we match only the named test.
    cargo test -p ruff --test "$file" --no-fail-fast --color=never \
        -- --exact --nocapture "$name" \
        > "$jlog" 2>>"$TEST_LOG" || true
}

for sel in "${FAIL_TO_PASS[@]}"; do
    log "F2P: $sel"
    run_one "$sel" "$REPORTS_DIR/f2p"
done
for sel in "${PASS_TO_PASS[@]}"; do
    log "P2P: $sel"
    run_one "$sel" "$REPORTS_DIR/p2p"
done

export REPORTS_DIR INSTANCE_ID
python3 - "$WS/f2p_effective.txt" "$WS/p2p_effective.txt" "$MODE" <<'PYEOF'
import json, os, sys, re
f2p_file, p2p_file, mode = sys.argv[1:4]
reports = os.environ['REPORTS_DIR']
iid = os.environ['INSTANCE_ID']

def classify_log(path, name):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return "ERROR"
    text = open(path).read()
    # libtest JSON form
    for ln in text.splitlines():
        ln = ln.strip()
        if not ln.startswith('{'): continue
        try: r = json.loads(ln)
        except Exception: continue
        if r.get("type") == "test" and r.get("name") == name:
            ev = r.get("event")
            if ev == "ok":      return "PASSED"
            if ev == "failed":  return "FAILED"
            if ev == "ignored": return "SKIPPED"
    # libtest text form: "test NAME ... ok|FAILED|ignored"
    pat = re.compile(r'^test\s+' + re.escape(name) + r'\s+\.\.\.\s+(ok|FAILED|ignored)')
    for ln in text.splitlines():
        m = pat.search(ln)
        if m:
            v = m.group(1)
            if v == "ok":      return "PASSED"
            if v == "FAILED":  return "FAILED"
            if v == "ignored": return "SKIPPED"
    # Compile failure markers
    if "error[E" in text or "could not compile" in text or "error: aborting" in text:
        return "ERROR"
    if "0 passed" in text and "0 failed" in text:
        # cargo ran but found no matching test (e.g. binary didn't compile)
        return "ERROR"
    return "ERROR"

def bucket(ids, kind):
    out = {"PASSED": [], "FAILED": [], "ERROR": [], "SKIPPED": []}
    for sel in ids:
        file, _, name = sel.partition("::")
        path = os.path.join(reports, kind, f"{file}_{name}.json")
        out[classify_log(path, name)].append(sel)
    return out

f2p_ids = [l.strip() for l in open(f2p_file) if l.strip()]
p2p_ids = [l.strip() for l in open(p2p_file) if l.strip()]
f2p = bucket(f2p_ids, "f2p")
p2p = bucket(p2p_ids, "p2p")
resolved = (len(f2p["PASSED"]) == len(f2p_ids)
            and len(p2p["PASSED"]) == len(p2p_ids))

grader = {"instance_id":iid, "mode":mode, "applied":True, "build":{"status":"ok"},
          "f2p":f2p, "p2p":p2p, "resolved":resolved}
def cnts(d, ids):
    return {"passed":len(d["PASSED"]),"failed":len(d["FAILED"]),
            "errored":len(d["ERROR"]),"skipped":len(d["SKIPPED"]),"total":len(ids)}
agent = {"instance_id":iid, "applied":True, "build":{"status":"ok"},
         "f2p":cnts(f2p, f2p_ids), "p2p":cnts(p2p, p2p_ids),
         "resolved":resolved, "error_categories":[]}
json.dump(grader, open("/out/grader_report.json","w"), indent=2)
json.dump(agent,  open("/out/agent_report.json","w"), indent=2)
print(json.dumps(grader, indent=2))
PYEOF

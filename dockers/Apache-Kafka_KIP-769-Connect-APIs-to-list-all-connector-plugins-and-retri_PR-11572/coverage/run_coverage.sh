#!/usr/bin/env bash
# Coverage runner for KIP-595.
#
# Kafka 2.4's build.gradle auto-applies the `jacoco` Gradle plugin to
# every non-:core project.  When a Test task runs, the plugin auto-
# attaches a javaagent and writes the .exec dump to
# `<module>/build/jacoco/<task-name>.exec`.  We just snapshot those
# files between F2P and P2P invocations.
#
# Output:
#   /out/coverage_report.json   per-file + summary
set -uo pipefail
PRIV=/opt/lolbench/private
WS=/workspace
KAFKA=$WS/kafka
SUITE=${LOLBENCH_SUITE:-orig}
HAS_AUG=0

JACOCO_CLI=/opt/jacoco/jacococli.jar

GRADLE_FLAGS=(
    --no-daemon
    -PscalaVersion=2.13
    -PenableTestCoverage=true
    -x rat
    -x checkstyleMain -x checkstyleTest
    -x spotbugsMain   -x spotbugsTest
)

log() { echo "[coverage $SUITE] $*" >&2; }

case "$SUITE" in
    orig|aug|union) ;;
    *) log "unknown LOLBENCH_SUITE=$SUITE"; exit 2 ;;
esac

if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi

if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    log "WARN: LOLBENCH_SUITE=$SUITE but no augmentation shipped; falling back to orig"
    SUITE=orig
fi

cd "$KAFKA"
git config --global --add safe.directory "$KAFKA"
git reset --hard >/dev/null 2>&1

log "applying solution.patch"
git apply "$PRIV/solution.patch"

log "re-assembling main + :connect:runtime + :connect:json"
gradle "${GRADLE_FLAGS[@]}" \
    :clients:jar :connect:runtime:classes :connect:json:classes \
    >"$WS/.cov_build.log" 2>&1
rc=$?
if [ "$rc" -ne 0 ]; then
    log "build failed (rc=$rc); tail:"; tail -30 "$WS/.cov_build.log" >&2
    exit 2
fi

log "applying eval_tests.patch"
git apply "$PRIV/eval_tests.patch"

if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
    log "applying eval_tests_aug.patch"
    git apply "$PRIV/eval_tests_aug.patch"
fi

mapfile -t FAIL_TO_PASS < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS < <(grep -v '^\s*$' "$PRIV/p2p.txt")
ORIG_F2P=("${FAIL_TO_PASS[@]}")
ORIG_P2P=("${PASS_TO_PASS[@]}")
if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
    mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
    case "$SUITE" in
      aug)
        FAIL_TO_PASS=("${FAIL_TO_PASS_AUG[@]}")
        PASS_TO_PASS=("${PASS_TO_PASS_AUG[@]}")
        ;;
      union)
        FAIL_TO_PASS=("${ORIG_F2P[@]}" "${FAIL_TO_PASS_AUG[@]}")
        PASS_TO_PASS=("${ORIG_P2P[@]}" "${PASS_TO_PASS_AUG[@]}")
        ;;
    esac
fi

SELECTED_F2P=/tmp/lolbench_f2p_selected.txt
SELECTED_P2P=/tmp/lolbench_p2p_selected.txt
printf "%s\n" "${FAIL_TO_PASS[@]}" > "$SELECTED_F2P"
printf "%s\n" "${PASS_TO_PASS[@]}" > "$SELECTED_P2P"

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

F2P_EXEC=$WS/jacoco_f2p.exec
P2P_EXEC=$WS/jacoco_p2p.exec
F2P_XML=$WS/jacoco_f2p.xml
P2P_XML=$WS/jacoco_p2p.xml
rm -f "$F2P_EXEC" "$P2P_EXEC" "$F2P_XML" "$P2P_XML"
rm -rf "$KAFKA"/connect/runtime/build/jacoco \
       "$KAFKA"/connect/json/build/jacoco \
       "$KAFKA"/connect/api/build/jacoco 2>/dev/null

# F2P
log "running F2P (:connect:runtime:test) — jacoco plugin auto-records exec"
gradle "${GRADLE_FLAGS[@]}" \
    :connect:runtime:test \
    $F2P_SELECTOR \
    --rerun-tasks --continue \
    -Dorg.gradle.workers.max=1 \
    >"$WS/.cov_f2p.log" 2>&1 || true

[ -f "$KAFKA/connect/runtime/build/jacoco/test.exec" ] \
    && cp "$KAFKA/connect/runtime/build/jacoco/test.exec" "$F2P_EXEC" \
    && log "F2P exec: $(ls -la "$F2P_EXEC")" \
    || log "F2P exec NOT produced"

# P2P
log "running P2P (:connect:json:test) — jacoco plugin auto-records exec"
gradle "${GRADLE_FLAGS[@]}" \
    :connect:json:test \
    $P2P_SELECTOR \
    --rerun-tasks --continue \
    -Dorg.gradle.workers.max=1 \
    >"$WS/.cov_p2p.log" 2>&1 || true

[ -f "$KAFKA/connect/json/build/jacoco/test.exec" ] \
    && cp "$KAFKA/connect/json/build/jacoco/test.exec" "$P2P_EXEC" \
    && log "P2P exec: $(ls -la "$P2P_EXEC")" \
    || log "P2P exec NOT produced"

# Generate XML reports against the production source the PR touched.
CLASSES_DIRS=(
    "$KAFKA/connect/runtime/build/classes/java/main"
    "$KAFKA/connect/api/build/classes/java/main"
)
SOURCES_DIRS=(
    "$KAFKA/connect/runtime/src/main/java"
    "$KAFKA/connect/api/src/main/java"
)

cf_args=()
for d in "${CLASSES_DIRS[@]}"; do [ -d "$d" ] && cf_args+=(--classfiles "$d"); done
sf_args=()
for d in "${SOURCES_DIRS[@]}"; do [ -d "$d" ] && sf_args+=(--sourcefiles "$d"); done

run_jacococli() {
    local exec_file=$1 xml_file=$2 label=$3
    if [ ! -s "$exec_file" ]; then
        log "  $label: missing/empty $exec_file; skipping report"
        return 1
    fi
    java -jar "$JACOCO_CLI" report "$exec_file" \
        "${cf_args[@]}" "${sf_args[@]}" \
        --xml "$xml_file" \
        --name "$label" \
        >>"$WS/.cov_cli.log" 2>&1
}
run_jacococli "$F2P_EXEC" "$F2P_XML" "F2P" || true
run_jacococli "$P2P_EXEC" "$P2P_XML" "P2P" || true

mkdir -p /out
set +e
python3 "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --kafka-root "$KAFKA" \
    --f2p-xml "$F2P_XML" \
    --p2p-xml "$P2P_XML" \
    --out /out/coverage_report.json
analyse_rc=$?
set -e
cp /out/coverage_report.json "$PRIV/coverage_report.json" 2>/dev/null || true

echo
echo "=== coverage_report summary ==="
python3 - <<'PY'
import json
r = json.load(open("/out/coverage_report.json"))
s = r["summary"]
print("  coverage_complete                  :", r.get("coverage_complete", False))
print("  lines added by solution.patch      :", s["lines_in_patch_total"])
print("  executable subset (denominator)    :", s["executable_lines_in_patch"])
print("  F2P covered                        : {:5d}  ({}%)".format(s["f2p_covered"],   s["f2p_pct"]))
print("  P2P covered                        : {:5d}  ({}%)".format(s["p2p_covered"],   s["p2p_pct"]))
print("  F2P union P2P covered              : {:5d}  ({}%)".format(s["union_covered"], s["union_pct"]))
PY

exit $analyse_rc

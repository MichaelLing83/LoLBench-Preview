#!/usr/bin/env bash
# Coverage runner for KIP-470.
#
# Kafka 2.4's build.gradle auto-applies the `jacoco` Gradle plugin to
# every non-:core project.  When a Test task runs, the plugin auto-
# attaches a javaagent and writes the .exec dump to
# `<module>/build/jacoco/<task-name>.exec`.  We just snapshot those
# files between F2P and P2P invocations.
#
# Output:
#   /out/coverage_report_${SUITE}.json   per-file + summary
#   /out/coverage_report.json            compatibility copy of the selected suite
set -uo pipefail
PRIV=/opt/lolbench/private
WS=/workspace
KAFKA=$WS/kafka
SUITE=${LOLBENCH_SUITE:-orig}
case "$SUITE" in
    orig|aug|union) ;;
    *) echo "[coverage] unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

JACOCO_CLI=/opt/jacoco/jacococli.jar

GRADLE_FLAGS=(
    --no-daemon
    -PscalaVersion=2.12
    -x rat
    -x checkstyleMain -x checkstyleTest
    -x spotbugsMain   -x spotbugsTest
)

log() { echo "[coverage $SUITE] $*" >&2; }

cd "$KAFKA"
git config --global --add safe.directory "$KAFKA"
git reset --hard >/dev/null 2>&1

log "applying solution.patch"
git apply "$PRIV/solution.patch"

log "re-assembling main + streams test-utils/examples classes + connect:json"
gradle "${GRADLE_FLAGS[@]}" \
    :clients:jar :streams:test-utils:classes :streams:examples:classes \
    :connect:json:classes \
    >"$WS/.cov_build.log" 2>&1
rc=$?
if [ "$rc" -ne 0 ]; then
    log "build failed (rc=$rc); tail:"; tail -30 "$WS/.cov_build.log" >&2
    exit 2
fi

log "applying eval_tests.patch"
git apply "$PRIV/eval_tests.patch"

if [ "$SUITE" != "orig" ]; then
    log "applying eval_tests_aug.patch"
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
SELECTED_F2P=/tmp/lolbench_kip470_cov_f2p.txt
SELECTED_P2P=/tmp/lolbench_kip470_cov_p2p.txt
case "$SUITE" in
    orig)
        cp "$PRIV/f2p.txt" "$SELECTED_F2P"
        cp "$PRIV/p2p.txt" "$SELECTED_P2P"
        ;;
    aug)
        cp "$PRIV/f2p_aug.txt" "$SELECTED_F2P"
        cp "$PRIV/p2p_aug.txt" "$SELECTED_P2P"
        ;;
    union)
        cat "$PRIV/f2p.txt" "$PRIV/f2p_aug.txt" > "$SELECTED_F2P"
        cat "$PRIV/p2p.txt" "$PRIV/p2p_aug.txt" > "$SELECTED_P2P"
        ;;
esac
F2P_SELECTOR=$(make_selectors "$SELECTED_F2P")
P2P_SELECTOR=$(make_selectors "$SELECTED_P2P")
log "F2P selector: $F2P_SELECTOR"
log "P2P selector: $P2P_SELECTOR"

F2P_EXEC=$WS/jacoco_f2p.exec
P2P_EXEC=$WS/jacoco_p2p.exec
F2P_XML=$WS/jacoco_f2p.xml
P2P_XML=$WS/jacoco_p2p.xml
rm -f "$F2P_EXEC" "$P2P_EXEC" "$F2P_XML" "$P2P_XML"
rm -rf "$KAFKA"/streams/test-utils/build/jacoco \
       "$KAFKA"/streams/examples/build/jacoco \
       "$KAFKA"/connect/json/build/jacoco 2>/dev/null

# F2P
log "running F2P (:streams:test-utils:test) — jacoco plugin auto-records exec"
gradle "${GRADLE_FLAGS[@]}" \
    :streams:test-utils:test \
    $F2P_SELECTOR \
    --rerun-tasks --continue \
    -Dorg.gradle.workers.max=1 \
    >"$WS/.cov_f2p.log" 2>&1 || true

[ -f "$KAFKA/streams/test-utils/build/jacoco/test.exec" ] \
    && cp "$KAFKA/streams/test-utils/build/jacoco/test.exec" "$F2P_EXEC" \
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
    "$KAFKA/streams/test-utils/build/classes/java/main"
    "$KAFKA/streams/examples/build/classes/java/main"
)
SOURCES_DIRS=(
    "$KAFKA/streams/test-utils/src/main/java"
    "$KAFKA/streams/examples/src/main/java"
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
OUT_REPORT="/out/coverage_report_${SUITE}.json"
python3 "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --kafka-root "$KAFKA" \
    --f2p-xml "$F2P_XML" \
    --p2p-xml "$P2P_XML" \
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
print("  coverage_complete                  :", r.get("coverage_complete", False))
print("  lines added by solution.patch      :", s["lines_in_patch_total"])
print("  executable subset (denominator)    :", s["executable_lines_in_patch"])
print("  F2P covered                        : {:5d}  ({}%)".format(s["f2p_covered"],   s["f2p_pct"]))
print("  P2P covered                        : {:5d}  ({}%)".format(s["p2p_covered"],   s["p2p_pct"]))
print("  F2P union P2P covered              : {:5d}  ({}%)".format(s["union_covered"], s["union_pct"]))
PY

exit $analyse_rc

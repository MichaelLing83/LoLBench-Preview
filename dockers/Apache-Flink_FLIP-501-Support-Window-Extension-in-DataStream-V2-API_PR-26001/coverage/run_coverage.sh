#!/usr/bin/env bash
# LoLBench coverage runner for Apache-Flink PR-26001 (FLIP-501).
set -uo pipefail
PRIV=/opt/lolbench/private
WS=/workspace
FLINK=$WS/flink
SUITE=${LOLBENCH_SUITE:-orig}

case "$SUITE" in
  orig|aug|union) ;;
  *) echo "[coverage] FATAL: unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac

HAS_AUG=0
if [ -f "$PRIV/eval_tests_aug.patch" ] \
   && [ -f "$PRIV/f2p_aug.txt" ] \
   && [ -f "$PRIV/p2p_aug.txt" ]; then
    HAS_AUG=1
fi
if [ "$SUITE" != "orig" ] && [ "$HAS_AUG" -eq 0 ]; then
    echo "[coverage] WARN: LOLBENCH_SUITE=$SUITE but no sidecar shipped; falling back to orig" >&2
    SUITE=orig
fi

JACOCO_AGENT=/opt/jacoco/jacocoagent.jar
JACOCO_CLI=/opt/jacoco/jacococli.jar

F2P_MODULE="flink-tests"
P2P_MODULE="flink-clients"

MAVEN_FLAGS=(
    -B -fae -o
    -Drat.skip=true -Dcheckstyle.skip=true
    -Dmaven.javadoc.skip=true
    -Denforcer.skip=true
    -Dspotbugs.skip=true
    -Dspotless.check.skip=true
    -Dsurefire.failIfNoSpecifiedTests=false
    -Djapicmp.skip=true
    -Dscalastyle.skip=true
)

log() { echo "[coverage/$SUITE] $*" >&2; }

# Hostname patch (MiniCluster calls getLocalHost())
HOSTNAME_SELF=$(hostname 2>/dev/null || true)
if [ -n "$HOSTNAME_SELF" ] && ! grep -q "$HOSTNAME_SELF" /etc/hosts; then
    echo "127.0.0.1 $HOSTNAME_SELF" >> /etc/hosts
fi


cd "$FLINK"
git config --global --add safe.directory "$FLINK"
git reset --hard >/dev/null 2>&1
git clean -fdx -e target -e '*/target' >/dev/null 2>&1

log "applying solution.patch"
git apply "$PRIV/solution.patch"

log "applying eval_tests.patch"
git apply "$PRIV/eval_tests.patch"
if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
    log "applying eval_tests_aug.patch"
    git apply "$PRIV/eval_tests_aug.patch"
fi

log "re-installing F2P + P2P modules with solution/test patches"
mvn "${MAVEN_FLAGS[@]}" \
    -pl "$F2P_MODULE,$P2P_MODULE" -am \
    -DskipTests install \
    >"$WS/.cov_install.log" 2>&1
if [ $? -ne 0 ]; then
    log "install failed; tail:"; tail -30 "$WS/.cov_install.log" >&2
    exit 2
fi

make_test_arg() {
    python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(",".join(ids))
' "$1"
}

mapfile -t F2P_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t P2P_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
F2P_AUG=()
P2P_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
    mapfile -t F2P_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
    mapfile -t P2P_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi
case "$SUITE" in
  orig)
    printf "%s\n" "${F2P_ORIG[@]}" > "$WS/.f2p_effective.txt"
    printf "%s\n" "${P2P_ORIG[@]}" > "$WS/.p2p_effective.txt"
    ;;
  aug)
    printf "%s\n" "${F2P_AUG[@]}" > "$WS/.f2p_effective.txt"
    printf "%s\n" "${P2P_AUG[@]}" > "$WS/.p2p_effective.txt"
    ;;
  union)
    printf "%s\n" "${F2P_ORIG[@]}" "${F2P_AUG[@]}" > "$WS/.f2p_effective.txt"
    printf "%s\n" "${P2P_ORIG[@]}" "${P2P_AUG[@]}" > "$WS/.p2p_effective.txt"
    ;;
esac

F2P_TESTS=$(make_test_arg "$WS/.f2p_effective.txt")
P2P_TESTS=$(make_test_arg "$WS/.p2p_effective.txt")

F2P_EXEC=$WS/jacoco_f2p.exec
P2P_EXEC=$WS/jacoco_p2p.exec
F2P_XML=$WS/jacoco_f2p.xml
P2P_XML=$WS/jacoco_p2p.xml
rm -f "$F2P_EXEC" "$P2P_EXEC" "$F2P_XML" "$P2P_XML"

run_jacoco_test() {
    local label=$1 module=$2 tests=$3 exec_file=$4 goal=${5:-test}
    log "running $label tests under jacoco agent (module=$module) — no -am, uses installed shaded jars"
    mvn "${MAVEN_FLAGS[@]}" \
        -pl "$module" \
        "-Dflink.surefire.baseArgLine=-XX:+UseG1GC -Xms256m -XX:+IgnoreUnrecognizedVMOptions --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED -Djunit.platform.reflection.search.useLegacySemantics=true -javaagent:${JACOCO_AGENT}=destfile=${exec_file}" \
        -Dtest="$tests" \
        "-Dit.test=$tests" \
        "$goal" \
        >"$WS/.cov_${label}.log" 2>&1 || true
    if [ -f "$exec_file" ]; then
        log "$label exec: $(ls -la "$exec_file")"
    else
        log "$label exec NOT produced"
    fi
}

run_jacoco_test f2p "$F2P_MODULE" "$F2P_TESTS" "$F2P_EXEC" verify
run_jacoco_test p2p "$P2P_MODULE" "$P2P_TESTS" "$P2P_EXEC"

CLASSES_DIRS=(
    "$FLINK/flink-runtime/target/classes"
    "$FLINK/flink-core-api/target/classes"
    "$FLINK/flink-datastream-api/target/classes"
    "$FLINK/flink-datastream/target/classes"
)
SOURCES_DIRS=(
    "$FLINK/flink-runtime/src/main/java"
    "$FLINK/flink-core-api/src/main/java"
    "$FLINK/flink-datastream-api/src/main/java"
    "$FLINK/flink-datastream/src/main/java"
)
cf_args=()
for d in "${CLASSES_DIRS[@]}"; do [ -d "$d" ] && cf_args+=(--classfiles "$d"); done
sf_args=()
for d in "${SOURCES_DIRS[@]}"; do [ -d "$d" ] && sf_args+=(--sourcefiles "$d"); done

run_jacococli() {
    local exec_file=$1 xml_file=$2 label=$3
    if [ ! -s "$exec_file" ]; then
        log "  $label: missing/empty $exec_file; skip"; return 1
    fi
    java -jar "$JACOCO_CLI" report "$exec_file" \
        "${cf_args[@]}" "${sf_args[@]}" \
        --xml "$xml_file" --name "$label" \
        >>"$WS/.cov_cli.log" 2>&1
}
run_jacococli "$F2P_EXEC" "$F2P_XML" "F2P" || true
run_jacococli "$P2P_EXEC" "$P2P_XML" "P2P" || true

mkdir -p /out
set +e
python3 "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --flink-root "$FLINK" \
    --f2p-xml "$F2P_XML" --p2p-xml "$P2P_XML" \
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
print("  F2P covered                        : {:5d}  ({}%)".format(s["f2p_covered"], s["f2p_pct"]))
print("  P2P covered                        : {:5d}  ({}%)".format(s["p2p_covered"], s["p2p_pct"]))
print("  F2P union P2P covered              : {:5d}  ({}%)".format(s["union_covered"], s["union_pct"]))
PY
exit $analyse_rc

#!/usr/bin/env bash
set -uo pipefail

PRIV=/opt/lolbench/private
WS=/workspace
FLINK=$WS/flink
JACOCO_AGENT=/opt/jacoco/jacocoagent.jar
JACOCO_CLI=/opt/jacoco/jacococli.jar
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

F2P_MODULE="flink-tests"
P2P_MODULE="flink-clients"

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

log() { echo "[coverage/$SUITE] $*" >&2; }

HOSTNAME_SELF=$(hostname 2>/dev/null || true)
if [ -n "$HOSTNAME_SELF" ] && ! grep -q "$HOSTNAME_SELF" /etc/hosts; then
  echo "127.0.0.1 $HOSTNAME_SELF" >> /etc/hosts
fi

cd "$FLINK"
git config --global --add safe.directory "$FLINK"
git reset --hard >/dev/null 2>&1

log "applying solution.patch and eval_tests.patch"
git apply "$PRIV/solution.patch"
git apply "$PRIV/eval_tests.patch"
if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
  git apply "$PRIV/eval_tests_aug.patch"
fi

log "production compile/install with test compilation disabled"
mvn "${MAVEN_FLAGS[@]}" \
  -Dmaven.test.skip=true \
  -pl "$F2P_MODULE,$P2P_MODULE" -am \
  install >"$WS/.cov_install.log" 2>&1
if [ $? -ne 0 ]; then
  log "install failed"; tail -60 "$WS/.cov_install.log" >&2
  exit 2
fi

make_test_arg() {
  python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(",".join(ids))
' "$1"
}

mapfile -t FAIL_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/f2p.txt")
mapfile -t PASS_TO_PASS_ORIG < <(grep -v '^\s*$' "$PRIV/p2p.txt")
FAIL_TO_PASS_AUG=()
PASS_TO_PASS_AUG=()
if [ "$HAS_AUG" -eq 1 ]; then
  mapfile -t FAIL_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/f2p_aug.txt")
  mapfile -t PASS_TO_PASS_AUG < <(grep -v '^\s*$' "$PRIV/p2p_aug.txt")
fi

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

F2P_EFFECTIVE=$WS/.cov_f2p_effective.txt
P2P_EFFECTIVE=$WS/.cov_p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" >"$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" >"$P2P_EFFECTIVE"

F2P_TESTS=$(make_test_arg "$F2P_EFFECTIVE")
P2P_TESTS=$(make_test_arg "$P2P_EFFECTIVE")
F2P_EXEC=$WS/jacoco_f2p.exec
P2P_EXEC=$WS/jacoco_p2p.exec
F2P_XML=$WS/jacoco_f2p.xml
P2P_XML=$WS/jacoco_p2p.xml
rm -f "$F2P_EXEC" "$P2P_EXEC" "$F2P_XML" "$P2P_XML"

run_jacoco_test() {
  local label=$1 module=$2 tests=$3 exec_file=$4
  log "running $label selectors under JaCoCo"
  mvn "${MAVEN_FLAGS[@]}" \
    -pl "$module" \
    "-Dflink.surefire.baseArgLine=-XX:+UseG1GC -Xms256m -XX:+IgnoreUnrecognizedVMOptions --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED -Djunit.platform.reflection.search.useLegacySemantics=true -javaagent:${JACOCO_AGENT}=destfile=${exec_file}" \
    -Dtest="$tests" \
    test >"$WS/.cov_${label}.log" 2>&1 || true
  [ -f "$exec_file" ] && log "$label exec: $(ls -la "$exec_file")" || log "$label exec not produced"
}

run_jacoco_test f2p "$F2P_MODULE" "$F2P_TESTS" "$F2P_EXEC"
run_jacoco_test p2p "$P2P_MODULE" "$P2P_TESTS" "$P2P_EXEC"

MODULES=(
  flink-core-api
  flink-core
  flink-datastream-api
  flink-datastream
  flink-libraries/flink-state-processing-api
  flink-runtime
  flink-streaming-java
  flink-table/flink-table-runtime
  flink-tests
  flink-clients
)

cf_args=()
sf_args=()
for module in "${MODULES[@]}"; do
  [ -d "$FLINK/$module/target/classes" ] && cf_args+=(--classfiles "$FLINK/$module/target/classes")
  [ -d "$FLINK/$module/src/main/java" ] && sf_args+=(--sourcefiles "$FLINK/$module/src/main/java")
  [ -d "$FLINK/$module/src/main/scala" ] && sf_args+=(--sourcefiles "$FLINK/$module/src/main/scala")
done

run_jacococli() {
  local exec_file=$1 xml_file=$2 label=$3
  if [ ! -s "$exec_file" ]; then
    log "$label: missing/empty $exec_file"
    return 1
  fi
  java -jar "$JACOCO_CLI" report "$exec_file" \
    "${cf_args[@]}" "${sf_args[@]}" \
    --xml "$xml_file" --name "$label" >>"$WS/.cov_cli.log" 2>&1
}

run_jacococli "$F2P_EXEC" "$F2P_XML" F2P || true
run_jacococli "$P2P_EXEC" "$P2P_XML" P2P || true

mkdir -p /out
python3 "$PRIV/compute_coverage.py" \
  --solution-patch "$PRIV/solution.patch" \
  --flink-root "$FLINK" \
  --f2p-xml "$F2P_XML" \
  --p2p-xml "$P2P_XML" \
  --out /out/coverage_report.json
cp /out/coverage_report.json "$PRIV/coverage_report.json" 2>/dev/null || true

python3 - <<'PY'
import json
r = json.load(open("/out/coverage_report.json"))
s = r["summary"]
print("=== coverage_report summary ===")
print(f"coverage_complete: {r.get('coverage_complete')}")
print(f"executable_lines_in_patch: {s['executable_lines_in_patch']}")
print(f"union_covered: {s['union_covered']}")
print(f"union_pct: {s['union_pct']}")
PY

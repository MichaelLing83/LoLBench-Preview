#!/usr/bin/env bash
# LoLBench coverage runner for Apache-Flink PR-9976 (FLIP-77).
#
# Applies solution.patch + eval_tests.patch on top of base_commit and
# measures F2P/P2P line coverage of solution.patch using JaCoCo:
#   - JaCoCo agent is attached to every surefire fork via argLine and
#     writes an exec file per test invocation.
#   - jacococli generates an XML report against flink-core's compiled
#     classes + main sources.
#
# Runs everything as root — the container is only ever invoked by the
# trusted evaluator at curation time.
#
# Output:
#   /out/coverage_report.json   per-file + summary
#   /opt/lolbench/private/coverage_report.json   grader copy
#
# Exit codes:
#   0 — coverage report produced successfully.
#   2 — a tool failed; coverage_complete=false in the report.

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

MAVEN_FLAGS=(
    -B -fae
    -Drat.skip=true
    -Dcheckstyle.skip=true
    -Dmaven.javadoc.skip=true
    -Denforcer.skip=true
)

log() { echo "[coverage/$SUITE] $*" >&2; }

cd "$FLINK"
git config --global --add safe.directory "$FLINK"
git reset --hard >/dev/null 2>&1
git clean -fdx -e target -e '*/target' >/dev/null 2>&1

log "applying solution.patch + eval_tests.patch"
git apply "$PRIV/solution.patch"

# Re-install with the patched main sources (incremental — fast since
# the eval image already has the base build cached).
log "re-installing flink-core + flink-clients with solution.patch applied"
mvn "${MAVEN_FLAGS[@]}" \
    -pl flink-core,flink-clients \
    -am -DskipTests install \
    >"$WS/.cov_install.log" 2>&1
install_rc=$?
if [ "$install_rc" -ne 0 ]; then
    log "install failed (rc=$install_rc); tail:"
    tail -30 "$WS/.cov_install.log" >&2
    exit 2
fi

# eval_tests.patch goes on AFTER install — same reasoning as run_tests.sh:
# we want the test JVM to see the new tests but Maven's install phase to
# build only against the production source.
git apply "$PRIV/eval_tests.patch"

if [ "$HAS_AUG" -eq 1 ] && [ "$SUITE" != "orig" ]; then
    git apply "$PRIV/eval_tests_aug.patch"
fi

# Flink 1.10's parent POM hard-codes surefire's argLine WITHOUT a
# ${argLine} placeholder, so -DargLine on the command line is normally a
# no-op (the JaCoCo agent would never attach).  Sed-patch the root POM
# to prepend ${argLine} to surefire's argLine value so the JaCoCo
# -javaagent we pass on the command line actually reaches the fork JVM.
# This change lives only inside the coverage container; git-reset at
# the start of any new run wipes it.
log "patching root POM to honor user-provided \${argLine}"
sed -i 's|<argLine>-Xms256m|<argLine>${argLine} -Xms256m|' "$FLINK/pom.xml"
grep -n '<argLine>' "$FLINK/pom.xml" | head -2 >&2

# Build Surefire selectors the same way the eval runner does.
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
F2P_EFFECTIVE=$WS/.f2p_effective.txt
P2P_EFFECTIVE=$WS/.p2p_effective.txt
printf '%s\n' "${FAIL_TO_PASS[@]}" >"$F2P_EFFECTIVE"
printf '%s\n' "${PASS_TO_PASS[@]}" >"$P2P_EFFECTIVE"

F2P_SELECTOR=$(python3 -c '
import sys
ids = [l.strip() for l in open(sys.argv[1]) if l.strip()]
classes = []
for i in ids:
    cls = i.partition("#")[0].rsplit(".", 1)[1]
    if cls not in classes:
        classes.append(cls)
print(",".join(classes))
' "$F2P_EFFECTIVE")
P2P_SELECTOR=$(python3 -c '
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
' "$P2P_EFFECTIVE")
log "F2P selector: $F2P_SELECTOR"
log "P2P selector: $P2P_SELECTOR"

F2P_EXEC=$WS/jacoco_f2p.exec
P2P_EXEC=$WS/jacoco_p2p.exec
F2P_XML=$WS/jacoco_f2p.xml
P2P_XML=$WS/jacoco_p2p.xml
rm -f "$F2P_EXEC" "$P2P_EXEC" "$F2P_XML" "$P2P_XML"

# Wipe prior surefire reports.
rm -rf "$FLINK"/flink-core/target/surefire-reports \
       "$FLINK"/flink-clients/target/surefire-reports 2>/dev/null

# ---- F2P with JaCoCo --------------------------------------------------
# JaCoCo agent options:
#   destfile  — where the .exec dump is written
#   append=true — multiple forks (if any) merge into one exec; safer
#                 than overwrite when Flink's default forkCount > 1
#                 (Flink's parent POM resolves <forkCount> from
#                 ${flink.forkCount} which defaults to 1C).
#   includes=org.apache.flink.configuration.*  — only instrument the
#                                                 production package the
#                                                 PR touches (smaller exec).
#
# We *also* force forkCount=1 and reuseForks=true at the mvn cmdline.
# With multiple forks + append=true the merged exec would still be
# correct, but a single fork gives a tighter, more reproducible result
# and avoids any forkN/agent-init race.
log "running F2P tests with JaCoCo agent → $F2P_EXEC"
mvn "${MAVEN_FLAGS[@]}" -pl flink-core test \
    -Dtest="$F2P_SELECTOR" \
    -DfailIfNoTests=false \
    -Dsurefire.failIfNoSpecifiedTests=false \
    -Dflink.forkCount=1 -Dflink.reuseForks=true \
    -DargLine="-javaagent:$JACOCO_AGENT=destfile=$F2P_EXEC,append=true,includes=org.apache.flink.configuration.*" \
    >"$WS/.cov_f2p.log" 2>&1
f2p_rc=$?

# ---- P2P with JaCoCo --------------------------------------------------
log "running P2P tests with JaCoCo agent → $P2P_EXEC"
mvn "${MAVEN_FLAGS[@]}" -pl flink-clients test \
    -Dtest="$P2P_SELECTOR" \
    -DfailIfNoTests=false \
    -Dsurefire.failIfNoSpecifiedTests=false \
    -Dflink.forkCount=1 -Dflink.reuseForks=true \
    -DargLine="-javaagent:$JACOCO_AGENT=destfile=$P2P_EXEC,append=true,includes=org.apache.flink.configuration.*" \
    >"$WS/.cov_p2p.log" 2>&1
p2p_rc=$?

# ---- jacococli report-generation --------------------------------------
CLASSES_DIR="$FLINK/flink-core/target/classes"
SOURCES_DIR="$FLINK/flink-core/src/main/java"

run_jacococli() {
    local exec_file=$1 xml_file=$2 label=$3
    if [ ! -s "$exec_file" ]; then
        log "  $label: missing/empty $exec_file; skipping report"
        return 1
    fi
    java -jar "$JACOCO_CLI" report "$exec_file" \
        --classfiles "$CLASSES_DIR" \
        --sourcefiles "$SOURCES_DIR" \
        --xml "$xml_file" \
        --name "$label" \
        >>"$WS/.cov_cli.log" 2>&1
}
run_jacococli "$F2P_EXEC" "$F2P_XML" "F2P" || true
run_jacococli "$P2P_EXEC" "$P2P_XML" "P2P" || true

# ---- Analyse + emit report --------------------------------------------
mkdir -p /out
COVERAGE_OUT=/out/coverage_report.json
if [ "$SUITE" != "orig" ]; then
    COVERAGE_OUT=/out/coverage_report_aug.json
fi
export COVERAGE_OUT
set +e
python3 "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --flink-root "$FLINK" \
    --f2p-xml "$F2P_XML" \
    --p2p-xml "$P2P_XML" \
    --out "$COVERAGE_OUT"
analyse_rc=$?
set -e
cp "$COVERAGE_OUT" "$PRIV/$(basename "$COVERAGE_OUT")" 2>/dev/null || true

echo
echo "=== coverage_report summary ==="
python3 - <<'PY'
import json
import os
path = os.environ.get("COVERAGE_OUT", "/out/coverage_report.json")
r = json.load(open(path))
s = r["summary"]
print("  coverage_complete                  :", r.get("coverage_complete", False))
print("  lines added by solution.patch      :", s["lines_in_patch_total"])
print("  executable subset (denominator)    :", s["executable_lines_in_patch"])
print("  F2P covered                        : {:5d}  ({}%)".format(s["f2p_covered"],   s["f2p_pct"]))
print("  P2P covered                        : {:5d}  ({}%)".format(s["p2p_covered"],   s["p2p_pct"]))
print("  F2P union P2P covered              : {:5d}  ({}%)".format(s["union_covered"], s["union_pct"]))
if not r.get("coverage_complete", False):
    print()
    print("  tool_status:")
    for name, st in r.get("tool_status", {}).items():
        marker = "ok" if st.get("ok") else "FAIL"
        print(f"    {marker:4s}  {name}  {st.get('error','') or ''}")
PY

exit $analyse_rc

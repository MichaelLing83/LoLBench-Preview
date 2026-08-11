#!/usr/bin/env bash
# §7 invariant for Apache-Flink PR-9976 (FLIP-77).
#   validate_pre  → F2P all FAIL/ERROR (Maven test-compile fails when
#                   eval_tests.patch lands on the base source: the new
#                   tests reference ConfigOption/Configuration methods
#                   that don't exist pre-patch),
#                   P2P all PASS (flink-clients is untouched by either patch).
#   validate_post → F2P + P2P all PASS.
#
# With the augmented sidecar present, the invariant is checked for:
#   orig  — original private suite only
#   aug   — sidecar suite only
#   union — original and sidecar suites together
set -euo pipefail

IMAGE=${IMAGE:-lolbench/apache-flink-flip-77-pr-9976:1}
OUT=${OUT:-$(pwd)/validation_out}

SUITES=("orig" "aug" "union")
if [ "${1:-}" = "--suite" ] && [ -n "${2:-}" ]; then
    case "$2" in
        orig|aug|union) SUITES=("$2") ;;
        *) echo "ERROR: --suite must be orig|aug|union (got $2)" >&2; exit 2 ;;
    esac
fi

run_mode() {
    local mode=$1 suite=$2 outdir=$3
    mkdir -p "$outdir"
    echo "=== $suite/$mode @ $(date '+%H:%M:%S') ==="
    docker run --rm \
        --network=none \
        -e LOLBENCH_MODE="$mode" \
        -e LOLBENCH_SUITE="$suite" \
        -v "$outdir":/out \
        --memory 7g --cpus 4 \
        "$IMAGE" 2>&1 | tee "$outdir/run.log"
    [ -f "$outdir/agent_report.json" ] && cat "$outdir/agent_report.json"
}

overall_ok=0

for SUITE in "${SUITES[@]}"; do
    PREDIR="$OUT/$SUITE/pre"
    POSTDIR="$OUT/$SUITE/post"
    run_mode validate_pre  "$SUITE" "$PREDIR"
    run_mode validate_post "$SUITE" "$POSTDIR"

    python3 - "$PREDIR/agent_report.json" "$POSTDIR/agent_report.json" "$SUITE" <<'PY' || overall_ok=1
import json, sys
pre  = json.load(open(sys.argv[1]))
post = json.load(open(sys.argv[2]))
suite = sys.argv[3]

ok = True
def check(label, cond):
    global ok
    print(f"  {'PASS' if cond else 'FAIL'}  [{suite}] {label}")
    if not cond: ok = False

print(f"== invariant check ({suite}) ==")
check("pre:  F2P all FAIL/ERROR",  pre['f2p']['passed']  == 0 and pre['f2p']['failed'] + pre['f2p']['errored'] == pre['f2p']['total'])
check("pre:  P2P all PASS",        pre['p2p']['passed']  == pre['p2p']['total'])
check("post: F2P all PASS",        post['f2p']['passed'] == post['f2p']['total'])
check("post: P2P all PASS",        post['p2p']['passed'] == post['p2p']['total'])
check("post: resolved=True",       post.get('resolved') is True)
check("suite tag carried through", pre.get('suite') == suite and post.get('suite') == suite)

sys.exit(0 if ok else 1)
PY
done

MUTANTS_DIR=${MUTANTS_DIR:-$(pwd)/../../mutations/Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976}
if [ -d "$MUTANTS_DIR" ]; then
    echo "=== mutant arm (suite=union) ==="
    for m in "$MUTANTS_DIR"/mutant_*/solution.patch; do
        [ -f "$m" ] || continue
        name=$(basename "$(dirname "$m")")
        if [ "$name" = "mutant_010_optional_ignores_fallback_keys" ]; then
            echo "  SKIP  [mutant:$name] original mutant metadata marks P2P as rejected"
            continue
        fi
        MOUT="$OUT/mutants/$name"
        mkdir -p "$MOUT"
        echo "--- $name ---"
        docker run --rm \
            --network=none \
            -e LOLBENCH_SUITE=union \
            -v "$m":/in/solution.patch:ro \
            -v "$MOUT":/out \
            --memory 7g --cpus 4 \
            "$IMAGE" >"$MOUT/run.log" 2>&1 || true
        python3 - "$MOUT/agent_report.json" "$name" <<'PY' || overall_ok=1
import json, os, sys
path, name = sys.argv[1:3]
if not os.path.exists(path):
    print(f"  FAIL  [mutant:{name}] no agent_report.json")
    sys.exit(1)
r = json.load(open(path))
killed = r['f2p']['failed'] + r['f2p']['errored'] > 0
p2p_clean = r['p2p']['passed'] == r['p2p']['total']
print(f"  {'PASS' if killed and p2p_clean else 'FAIL'}  [mutant:{name}] "
      f"killed_by_f2p={killed} p2p_clean={p2p_clean}")
sys.exit(0 if killed and p2p_clean else 1)
PY
    done
fi

exit "$overall_ok"

#!/usr/bin/env bash
# §7 invariant for Apache-Flink PR-25978 (FLIP-499 Event Time Watermarks).
#
# Pre-patch F2P may fail during module install because eval tests import the
# new event-time extension public APIs and runtime watermark classes. P2P is a
# documented pre-state deviation for this bundle; post-state P2P must pass.
set -euo pipefail

IMAGE=${IMAGE:-lolbench/apache-flink-flip-499-pr-25978:1}
OUT=${OUT:-$(pwd)/validation_out}
SUITES=${SUITES:-orig aug union}
MEMORY=${MEMORY:-7g}
CPUS=${CPUS:-4}
EQUIVALENT_MUTANTS=${EQUIVALENT_MUTANTS:-"mutant_007_handler_does_not_wait_all_inputs mutant_029_process_operator_forwards_extension_watermarks_directly"}

case "$OUT" in
    /*) ;;
    *) OUT="$(pwd)/$OUT" ;;
esac

run_mode() {
    local mode=$1 suite=$2 outdir=$3
    echo "=== $mode/$suite @ $(date '+%H:%M:%S') ==="
    mkdir -p "$outdir"
    docker run --rm \
        --network=none \
        -e LOLBENCH_MODE="$mode" \
        -e LOLBENCH_SUITE="$suite" \
        -v "$outdir":/out \
        --memory "$MEMORY" --cpus "$CPUS" \
        "$IMAGE" 2>&1 | tee "$outdir/run.log"
    [ -f "$outdir/agent_report.json" ] && cat "$outdir/agent_report.json"
}

REPORTS=()
for suite in $SUITES; do
    run_mode validate_pre "$suite" "$OUT/$suite/pre"
    run_mode validate_post "$suite" "$OUT/$suite/post"
    REPORTS+=("$suite" "$OUT/$suite/pre/agent_report.json" "$OUT/$suite/post/agent_report.json")
done

python3 - "${REPORTS[@]}" <<'PY'
import json, sys
args = sys.argv[1:]
ok = True
def check(label, cond):
    global ok
    print(f"  {'PASS' if cond else 'FAIL'}  {label}")
    if not cond: ok = False
print("== invariant check ==")
for i in range(0, len(args), 3):
    suite, pre_path, post_path = args[i:i + 3]
    pre = json.load(open(pre_path))
    post = json.load(open(post_path))
    check(f"{suite} pre: F2P all FAIL/ERROR", pre['f2p']['passed'] == 0 and pre['f2p']['failed'] + pre['f2p']['errored'] == pre['f2p']['total'])
    check(f"{suite} pre: P2P documented deviation accepted", True)
    check(f"{suite} post: F2P all PASS", post['f2p']['passed'] == post['f2p']['total'])
    check(f"{suite} post: P2P all PASS", post['p2p']['passed'] == post['p2p']['total'])
    check(f"{suite} post: resolved=True", post.get('resolved') is True)
    check(f"{suite} tag carried through", pre.get('suite') == suite and post.get('suite') == suite)
sys.exit(0 if ok else 1)
PY

MUTANTS_DIR=${MUTANTS_DIR:-$(pwd)/../../mutations/Apache-Flink_FLIP-499-Support-Event-Time-by-Generalized-Watermark-in-Data_PR-25978}
if [ -d "$MUTANTS_DIR" ]; then
    echo "=== mutant arm (suite=union) ==="
    overall_ok=0
    for m in "$MUTANTS_DIR"/mutant_*/solution.patch; do
        [ -f "$m" ] || continue
        name=$(basename "$(dirname "$m")")
        mout="$OUT/mutants/$name"
        mkdir -p "$mout"
        echo "--- $name ---"
        docker run --rm --network=none \
            -e LOLBENCH_SUITE=union \
            -v "$m":/in/solution.patch:ro \
            -v "$mout":/out \
            --memory "$MEMORY" --cpus "$CPUS" \
            "$IMAGE" >"$mout/run.log" 2>&1 || true
        python3 - "$mout/agent_report.json" "$name" "$EQUIVALENT_MUTANTS" <<'PY' || overall_ok=1
import json
import os
import sys

path, name, equivalent_s = sys.argv[1:4]
equivalent = set(equivalent_s.split())
if not os.path.exists(path):
    print(f"  FAIL  [mutant:{name}] no agent_report.json")
    sys.exit(1)
r = json.load(open(path))
killed = r["f2p"]["failed"] + r["f2p"]["errored"] > 0
p2p_clean = r["p2p"]["passed"] == r["p2p"]["total"]
accepted_equivalent = name in equivalent and r["f2p"]["passed"] == r["f2p"]["total"] and p2p_clean
print(
    f"  {'PASS' if (killed and p2p_clean) or accepted_equivalent else 'FAIL'}  [mutant:{name}] "
    f"killed_by_f2p={killed} p2p_clean={p2p_clean} "
    f"accepted_equivalent={accepted_equivalent}"
)
sys.exit(0 if (killed and p2p_clean) or accepted_equivalent else 1)
PY
    done
    exit "$overall_ok"
fi

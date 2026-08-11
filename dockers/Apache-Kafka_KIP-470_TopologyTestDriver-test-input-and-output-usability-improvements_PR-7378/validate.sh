#!/usr/bin/env bash
# §7 invariant plus augmented-suite and mutant gates for Apache-Kafka
# PR-7378 (KIP-470).
set -euo pipefail

IMAGE=${IMAGE:-lolbench/apache-kafka-kip-470-pr-7378:1}
OUT=${OUT:-$(pwd)/validation_out}
INSTANCE_ID=Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378
ROOT=${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
MUT_DIR=${MUT_DIR:-$ROOT/mutations/$INSTANCE_ID}
mkdir -p "$OUT"

run_mode() {
    local suite=$1 mode=$2 outdir=$3
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

for suite in orig aug union; do
    mkdir -p "$OUT/$suite-pre" "$OUT/$suite-post"
    run_mode "$suite" validate_pre "$OUT/$suite-pre"
    run_mode "$suite" validate_post "$OUT/$suite-post"
done

if [ -d "$MUT_DIR" ]; then
    for patch in "$MUT_DIR"/mutant_*/solution.patch; do
        [ -f "$patch" ] || continue
        mutant=$(basename "$(dirname "$patch")")
        outdir="$OUT/mutant-$mutant"
        mkdir -p "$outdir"
        echo "=== union/eval $mutant @ $(date '+%H:%M:%S') ==="
        docker run --rm \
            --network=none \
            -e LOLBENCH_MODE=eval \
            -e LOLBENCH_SUITE=union \
            -v "$patch":/in/solution.patch:ro \
            -v "$outdir":/out \
            --memory 7g --cpus 4 \
            "$IMAGE" 2>&1 | tee "$outdir/run.log"
        [ -f "$outdir/agent_report.json" ] && cat "$outdir/agent_report.json"
    done
else
    echo "WARN: mutation directory not found: $MUT_DIR" >&2
fi

python3 - "$OUT" <<'PY'
import glob, json, os, sys
out = sys.argv[1]
ok = True

def check(label, cond):
    global ok
    print(f"  {'PASS' if cond else 'FAIL'}  {label}")
    if not cond: ok = False

print("== invariant check ==")
for suite in ("orig", "aug", "union"):
    pre = json.load(open(os.path.join(out, f"{suite}-pre", "agent_report.json")))
    post = json.load(open(os.path.join(out, f"{suite}-post", "agent_report.json")))
    check(f"{suite} pre: F2P all FAIL/ERROR",
          pre["f2p"]["passed"] == 0 and pre["f2p"]["failed"] + pre["f2p"]["errored"] == pre["f2p"]["total"])
    check(f"{suite} pre: P2P all PASS",
          pre["p2p"]["passed"] == pre["p2p"]["total"])
    check(f"{suite} post: F2P all PASS",
          post["f2p"]["passed"] == post["f2p"]["total"])
    check(f"{suite} post: P2P all PASS",
          post["p2p"]["passed"] == post["p2p"]["total"])
    check(f"{suite} post: resolved=True", post.get("resolved") is True)

mutant_reports = sorted(glob.glob(os.path.join(out, "mutant-*", "agent_report.json")))
for report in mutant_reports:
    name = os.path.basename(os.path.dirname(report)).removeprefix("mutant-")
    data = json.load(open(report))
    killed = data["f2p"]["failed"] + data["f2p"]["errored"] > 0
    p2p_clean = data["p2p"]["passed"] == data["p2p"]["total"]
    check(f"{name}: union F2P kills mutant", killed)
    check(f"{name}: union P2P clean", p2p_clean)

sys.exit(0 if ok else 1)
PY

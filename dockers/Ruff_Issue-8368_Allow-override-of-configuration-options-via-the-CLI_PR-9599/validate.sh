#!/usr/bin/env bash
# Strict invariant + mutant validation for Ruff PR-9599.
set -euo pipefail

IMAGE=${IMAGE:-lolbench/ruff-pr-9599:1}
OUT=${OUT:-$(pwd)/validation_out}
SUITES=${SUITES:-orig aug union}
MUTATIONS_DIR=${MUTATIONS_DIR:-../../mutations/Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599}

run_mode() {
    local suite=$1 mode=$2 outdir=$3
    mkdir -p "$outdir"
    echo "=== $mode/$suite @ $(date '+%H:%M:%S') ==="
    docker run --rm \
        --network=none \
        -e LOLBENCH_MODE="$mode" \
        -e LOLBENCH_SUITE="$suite" \
        -v "$outdir":/out \
        --memory 7g --cpus 4 \
        "$IMAGE" 2>&1 | tee "$outdir/run.log"
    [ -f "$outdir/agent_report.json" ] && cat "$outdir/agent_report.json"
}

for suite in $SUITES; do
    run_mode "$suite" validate_pre  "$OUT/$suite/pre"
    run_mode "$suite" validate_post "$OUT/$suite/post"
done

python3 - "$OUT" $SUITES <<'PY'
import json
import sys
from pathlib import Path

out = Path(sys.argv[1])
suites = sys.argv[2:]
ok = True

def check(label, cond):
    global ok
    print(f"  {'PASS' if cond else 'FAIL'}  {label}")
    if not cond:
        ok = False

print("== invariant check ==")
for suite in suites:
    pre = json.load(open(out / suite / "pre" / "agent_report.json"))
    post = json.load(open(out / suite / "post" / "agent_report.json"))
    check(f"{suite} pre:  F2P all FAIL/ERROR",
          pre["f2p"]["passed"] == 0 and pre["f2p"]["failed"] + pre["f2p"]["errored"] == pre["f2p"]["total"])
    check(f"{suite} pre:  P2P all PASS",
          pre["p2p"]["passed"] == pre["p2p"]["total"])
    check(f"{suite} post: F2P all PASS",
          post["f2p"]["passed"] == post["f2p"]["total"])
    check(f"{suite} post: P2P all PASS",
          post["p2p"]["passed"] == post["p2p"]["total"])
    check(f"{suite} post: resolved=True", post.get("resolved") is True)

sys.exit(0 if ok else 1)
PY

echo "=== mutant arm (suite=union) ==="
for patch in "$MUTATIONS_DIR"/mutant_*/solution.patch; do
    [ -f "$patch" ] || continue
    name=$(basename "$(dirname "$patch")")
    outdir="$OUT/mutants/$name"
    mkdir -p "$outdir"
    echo "--- $name ---"
    set +e
    ./eval.sh "$patch" --suite union --out "$outdir" > "$outdir/eval.log" 2>&1
    rc=$?
    set -e
    python3 - "$outdir/agent_report.json" "$name" <<'PY'
import json
import sys

report_path, name = sys.argv[1:3]
r = json.load(open(report_path))
f2p = r["f2p"]
p2p = r["p2p"]
killed = f2p["passed"] < f2p["total"]
p2p_clean = p2p["passed"] == p2p["total"]
ok = killed and p2p_clean
print(f"  {'PASS' if ok else 'FAIL'}  [mutant:{name}] killed_by_f2p={killed} p2p_clean={p2p_clean}")
sys.exit(0 if ok else 1)
PY
done

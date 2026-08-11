#!/usr/bin/env bash
# LoLBench correctness evaluation for Apache-Flink PR-26567 (FLIP-498).
set -euo pipefail
IMAGE=${IMAGE:-lolbench/apache-flink-flip-498-pr-26567:1}
MEMORY=${MEMORY:-7g}
CPUS=${CPUS:-4}
SUITE=${LOLBENCH_SUITE:-orig}

usage() {
    cat >&2 <<EOF
Usage: $0 <solution.patch> [--out <dir>] [--image <name>] [--suite orig|aug|union]
EOF
    exit 2
}
[ $# -ge 1 ] || usage
PATCH=""
OUT="$(pwd)/eval_out"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)  usage ;;
        --out)      OUT=$2;   shift 2 ;;
        --image)    IMAGE=$2; shift 2 ;;
        --suite)    SUITE=$2; shift 2 ;;
        -*)         echo "unknown option: $1" >&2; usage ;;
        *)          if [ -z "$PATCH" ]; then PATCH=$1; else SUITE=$1; fi; shift ;;
    esac
done
case "$SUITE" in orig|aug|union) ;; *) echo "ERROR: invalid suite '$SUITE'" >&2; exit 2 ;; esac
[ -f "$PATCH" ] || { echo "ERROR: $PATCH not found" >&2; exit 2; }
PATCH=$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")

mkdir -p "$OUT"; rm -f "$OUT/agent_report.json" "$OUT/run.log"
docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "ERROR: image '$IMAGE' not found" >&2; exit 2; }

set +e
docker run --rm --network=none --memory "$MEMORY" --cpus "$CPUS" \
    -e LOLBENCH_SUITE="$SUITE" \
    -v "$PATCH":/in/solution.patch:ro -v "$OUT":/out \
    "$IMAGE" > "$OUT/run.log" 2>&1
rc=$?
set -e
[ -f "$OUT/agent_report.json" ] || { tail -30 "$OUT/run.log" >&2; exit 1; }
python3 - "$OUT/agent_report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
print(f"[eval] {'RESOLVED' if r.get('resolved') else 'UNRESOLVED'}  build={r.get('build',{}).get('status','?')}  "
      f"suite={r.get('suite','?')}  "
      f"F2P {r['f2p']['passed']}/{r['f2p']['total']}  P2P {r['p2p']['passed']}/{r['p2p']['total']}")
sys.exit(0 if r.get('resolved') else 1)
PY

#!/usr/bin/env bash
# LoLBench correctness evaluation for Apache-Flink PR-9976 (FLIP-77).
#
# Usage:
#   ./eval.sh <path/to/solution.patch> [--out <dir>] [--image <name>] [--suite orig|aug|union]
set -euo pipefail

IMAGE=${IMAGE:-lolbench/apache-flink-flip-77-pr-9976:1}
MEMORY=${MEMORY:-7g}
CPUS=${CPUS:-4}
SUITE=${SUITE:-orig}

usage() {
    cat >&2 <<EOF
Usage: $0 <solution.patch> [--out <dir>] [--image <name>] [--suite orig|aug|union]

Options:
  --out <dir>     Where to drop agent_report.json + run.log (default: ./eval_out)
  --image <name>  Override image tag (default: $IMAGE)
  --suite <name>  Which test suite to run (default: orig):
                    orig  — original F2P/P2P only
                    aug   — augmented sidecar suite only
                    union — original and augmented suites combined
  -h, --help      Show this help.

Env overrides:  IMAGE, MEMORY (default 7g), CPUS (default 4), SUITE (default orig).
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
        --suite=*)  SUITE=${1#--suite=}; shift ;;
        -*)         echo "unknown option: $1" >&2; usage ;;
        *)          PATCH=$1; shift ;;
    esac
done
case "$SUITE" in
    orig|aug|union) ;;
    *) echo "ERROR: --suite must be orig|aug|union (got $SUITE)" >&2; exit 2 ;;
esac
[ -n "$PATCH" ] || { echo "ERROR: solution.patch path required" >&2; usage; }
[ -f "$PATCH" ] || { echo "ERROR: $PATCH not found" >&2; exit 2; }
PATCH=$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")

mkdir -p "$OUT"
rm -f "$OUT/agent_report.json" "$OUT/run.log"

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not on PATH" >&2; exit 2; }
docker image inspect "$IMAGE" >/dev/null 2>&1 || {
    echo "ERROR: image '$IMAGE' not found locally.  Build it first." >&2
    exit 2
}

echo "[eval] image  : $IMAGE"
echo "[eval] patch  : $PATCH"
echo "[eval] suite  : $SUITE"
echo "[eval] out    : $OUT"
echo "[eval] running container ..."

set +e
docker run --rm \
    --network=none \
    --memory "$MEMORY" --cpus "$CPUS" \
    -e LOLBENCH_SUITE="$SUITE" \
    -v "$PATCH":/in/solution.patch:ro \
    -v "$OUT":/out \
    "$IMAGE" > "$OUT/run.log" 2>&1
rc=$?
set -e

if [ ! -f "$OUT/agent_report.json" ]; then
    echo "[eval] FAILED: no agent_report.json (exit $rc)" >&2
    tail -30 "$OUT/run.log" >&2 || true
    exit 1
fi

python3 - "$OUT/agent_report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
applied = r.get("applied", False)
resolved = r.get("resolved", False)
build = r.get("build", {}).get("status", "?")
f2p = r.get("f2p", {})
p2p = r.get("p2p", {})
cats = r.get("error_categories", [])
verdict = "RESOLVED" if resolved else ("UNRESOLVED" if applied else "REJECTED")
print(f"[eval] {verdict}  build={build}  "
      f"F2P {f2p.get('passed',0)}/{f2p.get('total',0)}  "
      f"P2P {p2p.get('passed',0)}/{p2p.get('total',0)}"
      + (f"  [{','.join(cats)}]" if cats else ""))
sys.exit(0 if resolved else 1)
PY

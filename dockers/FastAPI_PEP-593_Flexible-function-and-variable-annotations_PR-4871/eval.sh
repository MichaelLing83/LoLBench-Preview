#!/usr/bin/env bash
# Eval the FastAPI PR-4871 instance.
set -euo pipefail

IMAGE=${IMAGE:-lolbench/fastapi-pr-4871:1}
MEMORY=${MEMORY:-4g}
CPUS=${CPUS:-2}
SUITE=${SUITE:-orig}

usage() {
    cat >&2 <<EOF
Usage: $0 <solution.patch> [--out <dir>] [--image <name>] [--suite orig|aug|union]

Options:
  --out <dir>     Where to drop agent_report.json + run.log (default: ./out)
  --image <name>  Override image tag (default: $IMAGE)
  --suite <name>  Which test suite to run: orig, aug, or union (default: $SUITE)
  -h, --help      Show this help.
EOF
    exit 2
}

PATCH=""
OUT=${OUT:-$(pwd)/out}
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage ;;
        --out) OUT=$2; shift 2 ;;
        --image) IMAGE=$2; shift 2 ;;
        --suite) SUITE=$2; shift 2 ;;
        --suite=*) SUITE=${1#--suite=}; shift ;;
        --) shift; PATCH=${1:-}; break ;;
        -*) echo "unknown option: $1" >&2; usage ;;
        *) PATCH=$1; shift ;;
    esac
done

[ -n "$PATCH" ] || PATCH="$(pwd)/solution.patch"
case "$SUITE" in
    orig|aug|union) ;;
    *) echo "ERROR: --suite must be orig|aug|union (got $SUITE)" >&2; exit 2 ;;
esac
[ -f "$PATCH" ] || { echo "ERROR: $PATCH not found" >&2; exit 2; }
PATCH=$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")

mkdir -p "$OUT"
rm -f "$OUT/agent_report.json" "$OUT/run.log"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "ERROR: image '$IMAGE' not found locally." >&2
    echo "Build it first or pull it from your registry." >&2
    exit 2
fi

echo "[eval] image  : $IMAGE"
echo "[eval] patch  : $PATCH"
echo "[eval] suite  : $SUITE"
echo "[eval] out    : $OUT"

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
    echo "[eval] FAILED: no agent_report.json produced (exit $rc)" >&2
    echo "[eval] last 30 lines of run.log:" >&2
    tail -30 "$OUT/run.log" >&2 || true
    exit 1
fi

python3 - "$OUT/agent_report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
f2p = r.get("f2p", {})
p2p = r.get("p2p", {})
verdict = "RESOLVED" if r.get("resolved") else ("UNRESOLVED" if r.get("applied") else "REJECTED")
print(f"[eval] {verdict}  suite={r.get('suite', '?')}  "
      f"build={r.get('build', {}).get('status', '?')}  "
      f"F2P {f2p.get('passed', 0)}/{f2p.get('total', 0)}  "
      f"P2P {p2p.get('passed', 0)}/{p2p.get('total', 0)}")
sys.exit(0 if r.get("resolved") else 1)
PY

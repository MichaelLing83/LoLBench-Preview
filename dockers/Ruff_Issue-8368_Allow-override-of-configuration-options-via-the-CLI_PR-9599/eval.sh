#!/usr/bin/env bash
# LoLBench correctness evaluation for Ruff PR-9599.
set -euo pipefail
IMAGE=${IMAGE:-lolbench/ruff-pr-9599:1}
MEMORY=${MEMORY:-7g}
CPUS=${CPUS:-4}
SUITE=${SUITE:-orig}

usage() {
    cat >&2 <<EOF
Usage: $0 <solution.patch> [--out <dir>] [--image <name>] [--suite orig|aug|union]
Env: IMAGE, MEMORY (7g), CPUS (4), SUITE (orig).
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
        *)          PATCH=$1; shift ;;
    esac
done
[ -n "$PATCH" ] || { echo "ERROR: solution.patch path required" >&2; usage; }
[ -f "$PATCH" ] || { echo "ERROR: $PATCH not found" >&2; exit 2; }
case "$SUITE" in orig|aug|union) ;; *) echo "ERROR: invalid suite '$SUITE'" >&2; usage ;; esac
PATCH=$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")

mkdir -p "$OUT"
rm -f "$OUT/agent_report.json" "$OUT/run.log"

docker image inspect "$IMAGE" >/dev/null 2>&1 || {
    echo "ERROR: image '$IMAGE' not found locally." >&2
    exit 2
}

echo "[eval] image  : $IMAGE"
echo "[eval] patch  : $PATCH"
echo "[eval] out    : $OUT"
echo "[eval] suite  : $SUITE"
echo "[eval] running container ..."

set +e
docker run --rm \
    --network=none \
    -e LOLBENCH_SUITE="$SUITE" \
    --memory "$MEMORY" --cpus "$CPUS" \
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

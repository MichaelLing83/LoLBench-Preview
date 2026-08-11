#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 path/to/solution.patch [--out out_dir]" >&2
  exit 2
fi

PATCH=$1
shift || true
OUT=out
SUITE=${LOLBENCH_SUITE:-orig}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out) OUT=$2; shift 2 ;;
    --suite) SUITE=$2; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$SUITE" in
  orig|aug|union) ;;
  *) echo "unknown suite: $SUITE" >&2; exit 2 ;;
esac

IMAGE=${IMAGE:-lolbench/apache-flink-flip-467-pr-25731:1}
mkdir -p "$OUT"

docker run --rm \
  --network=none \
  -e LOLBENCH_SUITE="$SUITE" \
  -v "$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")":/in/solution.patch:ro \
  -v "$(cd "$OUT" && pwd)":/out \
  --memory "${MEMORY:-8g}" --cpus "${CPUS:-4}" \
  "$IMAGE" 2>&1 | tee "$OUT/run.log"

python3 - "$OUT/agent_report.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
if r.get("resolved"):
    print("RESOLVED")
    raise SystemExit(0)
if not r.get("applied", True):
    print("REJECTED")
    raise SystemExit(1)
print("UNRESOLVED")
raise SystemExit(1)
PY

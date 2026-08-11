#!/usr/bin/env bash
# LoLBench correctness evaluation for CPython PR-101441 (PEP 709: Inlined Comprehensions).
#
# Usage:
#   ./eval.sh <path/to/solution.patch> [--out <dir>]
#
# Inputs:
#   solution.patch  — your agent's source-side diff against base_commit.
#                     No tests, no extra files; just the implementation.
#
# What this does:
#   1. Mounts solution.patch read-only into the eval image at /in/solution.patch.
#   2. The image (privately) applies your patch then the hidden eval_tests.patch,
#      rebuilds CPython incrementally, and runs the hidden F2P + P2P selection.
#   3. Captures the sanitized agent_report.json (no test IDs, no logs).
#   4. Prints a one-line verdict and exits 0 iff resolved=true.
#
# Output:
#   <out>/agent_report.json   — sanitized counts + resolved flag.
#   <out>/run.log             — stdout/stderr from the container.

set -euo pipefail

IMAGE=${IMAGE:-lolbench/cpython-pr-101441:1}
MEMORY=${MEMORY:-7g}
CPUS=${CPUS:-4}

usage() {
    cat >&2 <<EOF
Usage: $0 <solution.patch> [--out <dir>] [--image <name>]

Options:
  --out <dir>     Where to drop agent_report.json + run.log (default: ./eval_out)
  --image <name>  Override image tag (default: $IMAGE)
  -h, --help      Show this help.

Env overrides:
  IMAGE, MEMORY (default 7g), CPUS (default 4).

Note on capabilities:
  PEP 709 is a compiler change with two small Python-stdlib edits.
  No special capabilities are needed. The container runs with
  --network=none and the default seccomp profile.
EOF
    exit 2
}

[ $# -ge 1 ] || usage

PATCH=""
OUT="$(pwd)/eval_out"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)   usage ;;
        --out)       OUT=$2;   shift 2 ;;
        --image)     IMAGE=$2; shift 2 ;;
        --)          shift; PATCH=$1; break ;;
        -*)          echo "unknown option: $1" >&2; usage ;;
        *)           PATCH=$1; shift ;;
    esac
done

[ -n "$PATCH" ]      || { echo "ERROR: solution.patch path is required" >&2; usage; }
[ -f "$PATCH" ]      || { echo "ERROR: $PATCH not found" >&2; exit 2; }
PATCH=$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")

mkdir -p "$OUT"
rm -f "$OUT/agent_report.json" "$OUT/run.log"

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not on PATH" >&2; exit 2; }

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "ERROR: image '$IMAGE' not found locally." >&2
    echo "Build it first or pull it from your registry." >&2
    exit 2
fi

echo "[eval] image  : $IMAGE"
echo "[eval] patch  : $PATCH"
echo "[eval] out    : $OUT"
echo "[eval] running container ..."

set +e
docker run --rm \
    --network=none \
    --memory "$MEMORY" --cpus "$CPUS" \
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

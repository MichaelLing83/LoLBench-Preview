#!/usr/bin/env bash
# Run one LoLBench task through Harbor and print its reward.
#
# Usage: scripts/run_task.sh <task-id> [agent] [model] [suite] [extra harbor args...]
#   scripts/run_task.sh ruff_1
#   scripts/run_task.sh cpython_9 opencode openrouter/deepseek/deepseek-v4-pro union
#   scripts/run_task.sh ruff_1 oracle -            # gold parity check
set -euo pipefail

id=${1:?usage: run_task.sh <task-id> [agent] [model] [suite]}
agent=${2:-opencode}
model=${3:-openrouter/deepseek/deepseek-v4-pro}
suite=${4:-union}
shift $(( $# < 4 ? $# : 4 )) || true   # remaining args pass through to harbor

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

[ -d "harbor_tasks/$id" ] || { echo "no such task: harbor_tasks/$id" >&2; exit 1; }

# Load .env if present (never overrides an already-exported var).
if [ -f .env ]; then set -a; . ./.env; set +a; fi

# Model flag: agents like `oracle`/`nop` take no model (pass model as `-` to skip).
model_args=()
if [ "$agent" != "oracle" ] && [ "$agent" != "nop" ] && [ "$model" != "-" ]; then
  model_args=(-m "$model")
fi

job="${id}_${agent}_${suite}"
echo ">> $id  agent=$agent  model=${model_args[*]:-none}  suite=$suite"

harbor run \
  -p "harbor_tasks/$id" \
  -a "$agent" ${model_args[@]+"${model_args[@]}"} \
  --job-name "$job" --jobs-dir "harbor_runs/$id" \
  --no-delete -n 1 -y \
  --ve "LOLBENCH_SUITE=$suite" \
  "$@"

reward=$(find "harbor_runs/$id/$job" -path '*/verifier/reward.json' 2>/dev/null | head -1)
if [ -n "$reward" ]; then
  echo -n "== $id reward: "
  python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reward'])" "$reward"
else
  echo "== $id: no reward.json produced" >&2
fi

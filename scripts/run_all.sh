#!/usr/bin/env bash
# Run all 20 LoLBench tasks through Harbor, N in parallel, and print a summary.
#
# Usage: scripts/run_all.sh [agent] [model] [suite] [parallelism]
#   scripts/run_all.sh                                    # defaults below
#   scripts/run_all.sh opencode openrouter/deepseek/deepseek-v4-pro union 4
set -uo pipefail

agent=${1:-opencode}
model=${2:-openrouter/deepseek/deepseek-v4-pro}
suite=${3:-union}
par=${4:-4}

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
if [ -f .env ]; then set -a; . ./.env; set +a; fi

# portable (works on macOS bash 3.2 — no `mapfile`); task ids have no whitespace
ids=(); while IFS= read -r x; do ids+=("$x"); done < <(cd harbor_tasks && ls -d */ | sed 's#/##' | sort)
echo "running ${#ids[@]} tasks  agent=$agent  model=$model  suite=$suite  parallelism=$par"

# One task per worker; `xargs -P` bounds concurrency across tasks.
printf '%s\n' "${ids[@]}" | xargs -P "$par" -I{} bash -c \
  'scripts/run_task.sh "$1" "'"$agent"'" "'"$model"'" "'"$suite"'" >"harbor_runs/{}.log" 2>&1 || true' _ {}

echo
echo "==================== reward summary ===================="
total=0; solved=0
for id in "${ids[@]}"; do
  r=$(find "harbor_runs/$id/${id}_${agent}_${suite}" -path '*/verifier/reward.json' 2>/dev/null | head -1)
  if [ -n "$r" ]; then
    v=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reward'])" "$r" 2>/dev/null || echo "?")
  else
    v="no-report"
  fi
  printf '  %-12s %s\n' "$id" "$v"
  total=$((total+1)); [ "$v" = "1.0" ] && solved=$((solved+1))
done
echo "-------------------------------------------------------"
echo "resolved: $solved / $total"

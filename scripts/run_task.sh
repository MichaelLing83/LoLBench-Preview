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

# Auto-allowlist the provider's API host. Tasks bake an agent-phase allowlist of
# openrouter.ai / api.openai.com / api.anthropic.com; any OTHER provider host is
# intercepted by the egress sidecar and the agent fails with an opaque
# "unknown certificate verification error". Add the host for known providers.
host_args=()
case "${model%%/*}" in
  deepseek)  host_args=(--allow-agent-host api.deepseek.com) ;;
  moonshot)  host_args=(--allow-agent-host api.moonshot.cn) ;;
  mistral)   host_args=(--allow-agent-host api.mistral.ai) ;;
  groq)      host_args=(--allow-agent-host api.groq.com) ;;
  xai)       host_args=(--allow-agent-host api.x.ai) ;;
esac
# Extend with LOLBENCH_ALLOW_HOSTS="host1 host2" for any other provider.
# WARNING: allowlist ONLY model endpoints. Adding a source host (github.com,
# pypi.org, maven, a git mirror, ...) hands the agent the gold patch and
# invalidates the run — see ANTI_CHEAT.md.
for h in ${LOLBENCH_ALLOW_HOSTS:-}; do
  case "$h" in
    *github*|*gitlab*|*bitbucket*|*gitee*|*googlesource*|*pypi*|*pythonhosted*|*maven*|*apache.org*|*sourceforge*)
      echo "REFUSING to allowlist source host '$h' — it would leak the gold solution (see ANTI_CHEAT.md)" >&2
      exit 2 ;;
  esac
  host_args+=(--allow-agent-host "$h")
done

job="${id}_${agent}_${suite}"
echo ">> $id  agent=$agent  model=${model_args[*]:-none}  suite=$suite  ${host_args[*]:-}"

harbor run \
  -p "harbor_tasks/$id" \
  -a "$agent" ${model_args[@]+"${model_args[@]}"} \
  ${host_args[@]+"${host_args[@]}"} \
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

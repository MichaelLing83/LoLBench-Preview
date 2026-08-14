"""Reference Harbor agent adapter for DeepSeek Harness — `dsh`
(https://github.com/deepseek-ai/deepseek-harness, npm `@deepseek-ai/dsh`).

A second worked custom-agent example (see CUSTOM_AGENT.md), alongside Chrys. It
subclasses Harbor's ``BaseInstalledAgent`` and drives the dsh **headless CLI**:

  install()  install Node + `@deepseek-ai/dsh`; pre-initialize the headless profile
             while the setup phase still has broad network.
  run()      cd the task repo, `dsh --profile headless "<task>"` (dsh uses the cwd
             as its workspace root and edits files with its bash/atomic-write
             tools), then `lolbench-submit`.

dsh talks to https://api.deepseek.com and reads DEEPSEEK_API_KEY, so allowlist the
endpoint for the agent run and pass the key (the .env key is spelled
DEEPSEEK_HARNESS_API_KEY):

    export DEEPSEEK_HARNESS_API_KEY=sk-...
    PYTHONPATH=. harbor run -p harbor_tasks/ruff_1 \
      -a agents.dsh_agent:DshAgent \
      --ae DEEPSEEK_API_KEY=$DEEPSEEK_HARNESS_API_KEY \
      --allow-agent-host api.deepseek.com \
      --agent-setup-timeout-multiplier 10 \
      --job-name ruff_1_dsh --jobs-dir harbor_runs/ruff_1 --no-delete -n 1 -y \
      --ve LOLBENCH_SUITE=union

NOTE: template — validate on ruff_1 before a full sweep.
"""
from __future__ import annotations

from typing import override

from harbor.agents.installed.base import BaseInstalledAgent
from harbor.environments.base import BaseEnvironment
from harbor.models.agent.context import AgentContext

DSH_PKG = "@deepseek-ai/dsh@0.1.0-rc.6"   # pin the release for reproducibility
NODE_VERSION = "22"
DEEPSEEK_BASE_URL = "https://api.deepseek.com"


class DshAgent(BaseInstalledAgent):
    """Run the DeepSeek Harness headless CLI inside a LoLBench Harbor task."""

    @staticmethod
    @override
    def name() -> str:
        return "dsh"

    @override
    def get_version_command(self) -> str | None:
        return '. "$HOME/.nvm/nvm.sh" 2>/dev/null; dsh --help >/dev/null 2>&1 && echo dsh-installed'

    @override
    async def install(self, environment: BaseEnvironment) -> None:
        # Setup phase has the network needed to install tooling; the task-solving
        # run() is restricted to the model allowlist.
        await self.ensure_system_dependencies(environment, ("curl", "git"))
        await self.exec_as_agent(environment, command=(
            "set -euo pipefail; "
            'export NVM_DIR="$HOME/.nvm"; '
            "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash; "
            '. "$NVM_DIR/nvm.sh"; '
            f"nvm install {NODE_VERSION}; nvm alias default {NODE_VERSION}; "
            # node-pty and koffi ship no linux prebuilds and must compile from
            # source. Building the whole dependency tree at once starves koffi's
            # heavy cnoke build and fails node-pty's. Instead install with
            # --ignore-scripts (skip all native auto-builds; koffi is unused by the
            # headless plugin tree) and then rebuild ONLY node-pty, which the
            # headless `dsh-subprocess` plugin requires and which builds cleanly alone.
            f"npm i -g pnpm {DSH_PKG} --ignore-scripts; "
            '( cd "$(npm root -g)/@deepseek-ai/dsh" && npm rebuild node-pty ); '
            "dsh --help >/dev/null; "
            # The web/headless profiles auto-initialize from a bundled template on
            # first use; trigger it now (network open) so the run phase — allowlisted
            # to the model endpoint only — never has to fetch a plugin.
            "dsh --profile headless --dump-config >/dev/null 2>&1 || true"
        ))

    @override
    async def run(self, instruction: str, environment: BaseEnvironment, context: AgentContext) -> None:
        # dsh reads DEEPSEEK_API_KEY (+ optional DEEPSEEK_BASE_URL) from its env.
        # extra_env carries the --ae'd key; we do not use Harbor's model routing.
        env = dict(self.extra_env)
        env.setdefault("DEEPSEEK_BASE_URL", DEEPSEEK_BASE_URL)

        # Write the instruction to a file dsh reads as its task.
        await self.exec_as_agent(environment, command=(
            "set -eu; mkdir -p /logs/agent/dsh; "
            f"cat > /tmp/lolbench_task.md <<'LOLBENCH_TASK_EOF'\n{instruction}\nLOLBENCH_TASK_EOF"
        ))

        # Solve, then submit. The repo is checked out at /workspace/<project> (e.g.
        # /workspace/ruff); dsh uses the cwd as its workspace root. lolbench-submit
        # captures the working-tree diff to /logs/artifacts/solution.patch — the
        # artifact the verifier grades.
        await self.exec_as_agent(environment, env=env, command=(
            'export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"; '
            'repo=$(dirname "$(find /workspace -maxdepth 2 -type d -name .git 2>/dev/null | head -1)"); '
            '[ -n "$repo" ] && [ "$repo" != "." ] || repo=/workspace; cd "$repo"; '
            'dsh --profile headless "$(cat /tmp/lolbench_task.md)" 2>&1 | tee /logs/agent/dsh.txt; '
            'lolbench-submit "$repo" || true'
        ))

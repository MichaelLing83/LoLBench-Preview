"""Reference Harbor agent adapter for Chrys (https://github.com/0x7c13/chrys).

Shows how to run a non-built-in agent against LoLBench. It subclasses Harbor's
``BaseInstalledAgent`` — the base for CLI agents that install themselves in the
container (the same base ``opencode`` uses). You implement:

  name()                short agent name
  get_version_command() a shell command that verifies the install (or None)
  install()             install the agent + tools; write its config
  run()                 solve the task, then submit the patch

It mirrors how the upstream LoLBench harness runs Chrys
(``scripts/run_chrys_incontainer.sh`` + ``scripts/agent/chrys_*.yaml/sh``).

Run it (from the repo root, with this dir importable):

    export OPENROUTER_API_KEY=sk-or-...
    PYTHONPATH=. harbor run -p harbor_tasks/ruff_1 \
      -a agents.chrys_agent:ChrysAgent \
      -m openrouter/deepseek/deepseek-v4-pro \
      --ae OPENROUTER_API_KEY=$OPENROUTER_API_KEY \
      --ae GITHUB_TOKEN=$(gh auth token) \
      --agent-setup-timeout-multiplier 10 \
      --job-name ruff_1_chrys --jobs-dir harbor_runs/ruff_1 --no-delete -n 1 -y \
      --ve LOLBENCH_SUITE=union

Chrys is a PRIVATE repo, so the sandbox needs a token (`--ae GITHUB_TOKEN`); a
public agent repo needs none. Chrys reads OPENROUTER_API_KEY from its env
(`--ae OPENROUTER_API_KEY`), and its uv-based install exceeds the default 360 s
setup budget (`--agent-setup-timeout-multiplier 10`).

NOTE: this is a template. Exact base-class APIs can shift between Harbor
versions; inspect yours with
``python -c "import inspect,harbor.agents.installed.base as b;print(inspect.getsource(b.BaseInstalledAgent))"``
and adjust. Validate on ``ruff_1`` before a full sweep.
"""
from __future__ import annotations

from typing import override

from harbor.agents.installed.base import BaseInstalledAgent
from harbor.environments.base import BaseEnvironment
from harbor.models.agent.context import AgentContext

CHRYS_REPO = "https://github.com/0x7c13/chrys.git"
CHRYS_PIN = "562db063"          # pin a commit for reproducibility
# Install under the agent user's HOME — the agent phase runs as a non-root user
# ("agent"), which cannot write to /opt. $HOME is expanded by the shell at run time.
CHRYS_DIR = "$HOME/chrys"
PROFILE_ID = "lolbench"


class ChrysAgent(BaseInstalledAgent):
    """Run the Chrys coding agent inside a LoLBench Harbor task."""

    @staticmethod
    @override
    def name() -> str:
        return "chrys"

    @override
    def get_version_command(self) -> str | None:
        return f"{CHRYS_DIR}/.venv/bin/chrys --help >/dev/null 2>&1 && echo chrys-installed"

    @override
    async def install(self, environment: BaseEnvironment) -> None:
        # The setup/install phase has the network needed to install tooling. The
        # task-solving run() that follows is restricted to the model allowlist.
        await self.ensure_system_dependencies(environment, ("git", "curl"))

        # Install uv, fetch + build Chrys (uv-managed Python 3.14). We download the
        # pinned source tarball via curl rather than `git clone`: the sandbox reaches
        # github over HTTPS (curl) but `git clone` trips an auth prompt through the
        # egress proxy. A PUBLIC agent repo needs no credentials; Chrys is PRIVATE, so
        # pass a token to the agent (`--ae GITHUB_TOKEN=$(gh auth token)`) — the
        # authenticated API-tarball endpoint resolves any commit for a private repo.
        # GIT_TERMINAL_PROMPT=0 stops any git-sourced `uv sync` dep hanging on a prompt.
        await self.exec_as_agent(environment, command=(
            "set -euo pipefail; export GIT_TERMINAL_PROMPT=0; "
            "command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh; "
            'export PATH="$HOME/.local/bin:$PATH"; '
            f"rm -rf {CHRYS_DIR}; mkdir -p {CHRYS_DIR}; "
            'if [ -n "${GITHUB_TOKEN:-}" ]; then '
            f'  curl -LsSf -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/0x7c13/chrys/tarball/{CHRYS_PIN} | tar xz -C {CHRYS_DIR} --strip-components=1; '
            "else "
            f"  curl -LsSf https://github.com/0x7c13/chrys/archive/{CHRYS_PIN}.tar.gz | tar xz -C {CHRYS_DIR} --strip-components=1; "
            "fi; "
            f"cd {CHRYS_DIR}; "
            "uv python install 3.14; uv sync --extra all; "
            ".venv/bin/chrys run --help >/dev/null"
        ), env=self.extra_env)   # forwards --ae vars (e.g. GITHUB_TOKEN) into the install shell

        # Write the model profile. provider/model come from self.model_name
        # (e.g. 'openrouter/deepseek/deepseek-v4-pro' -> provider 'openrouter',
        # model 'deepseek/deepseek-v4-pro'); OpenRouter speaks /chat/completions.
        provider, _, model_id = (self.model_name or "").partition("/")
        base_url = self.model_connection.configured_base_url or "https://openrouter.ai/api/v1"
        key_env = "OPENROUTER_API_KEY" if provider == "openrouter" else f"{provider.upper()}_API_KEY"
        profile = (
            f"id: {PROFILE_ID}\n"
            f"name: {PROFILE_ID}\n"
            "provider: openai\n"            # OpenAI-compatible wire (OpenRouter)
            "api_style: chat_completions\n"
            f"model_id: {model_id}\n"
            f"base_url: {base_url}\n"
            f'api_key: "{{{{{key_env}}}}}"\n'   # chrys resolves {{ENV}} at runtime
            "stream: true\n"
            "http_read_timeout: 1800.0\n"
        )
        await self.exec_as_agent(environment, command=(
            "set -eu; mkdir -p ~/.chrys/models; "
            f"cat > ~/.chrys/models/{PROFILE_ID}.yaml <<'LOLBENCH_PROFILE_EOF'\n{profile}LOLBENCH_PROFILE_EOF"
        ))

        # Anti-cheat: Chrys runs on its OWN uv Python, which the eval image's
        # stdlib strip does not reach. Remove the whole-module deliverables so a
        # PEP-680/PEP-615 agent can't copy them out of its own interpreter.
        await self.exec_as_agent(environment, command=(
            'find "$HOME/.local/share/uv/python" -type d '
            r'\( -name tomllib -o -name test \) -path "*python3.14*" '
            "-prune -exec rm -rf {} + 2>/dev/null || true"
        ))

    @override
    async def run(self, instruction: str, environment: BaseEnvironment, context: AgentContext) -> None:
        # Chrys reads the model key from OPENROUTER_API_KEY (its profile resolves
        # {{OPENROUTER_API_KEY}}). model_connection.env carries it, and any --ae var
        # (e.g. `--ae OPENROUTER_API_KEY=...`, `--ae GITHUB_TOKEN=...`) is also merged
        # in so the key reliably reaches Chrys regardless of how it was provided.
        env = {**dict(self.model_connection.env), **self.extra_env}
        env["CHRYS_MODEL_PROFILE"] = PROFILE_ID
        env["CHRYS_SESSION_ROOT_DIR"] = "/logs/agent/chrys"
        env["CHRYS_SESSION_TITLE_AUTO"] = "0"

        # Write the instruction to a file Chrys reads as its task.
        await self.exec_as_agent(environment, command=(
            "set -eu; mkdir -p /logs/agent/chrys; "
            f"cat > /tmp/lolbench_task.md <<'LOLBENCH_TASK_EOF'\n{instruction}\nLOLBENCH_TASK_EOF"
        ))

        # Solve, then submit. The repo is checked out at /workspace/<project> (e.g.
        # /workspace/ruff), so detect the git worktree rather than assuming /workspace.
        # Chrys edits files there; lolbench-submit captures the diff to
        # /logs/artifacts/solution.patch — the artifact the verifier grades. We call
        # it explicitly so the patch is captured even if the model didn't run it.
        await self.exec_as_agent(environment, env=env, command=(
            'export PATH="$HOME/.local/bin:$PATH"; '
            'repo=$(dirname "$(find /workspace -maxdepth 2 -type d -name .git 2>/dev/null | head -1)"); '
            '[ -n "$repo" ] && [ "$repo" != "." ] || repo=/workspace; cd "$repo"; '
            f'{CHRYS_DIR}/.venv/bin/chrys run --task /tmp/lolbench_task.md '
            f'--agent Code --workdir "$repo" --json 2>&1 | tee /logs/agent/chrys.txt; '
            'lolbench-submit "$repo" || true'
        ))

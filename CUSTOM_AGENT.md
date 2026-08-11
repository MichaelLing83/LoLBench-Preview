# Running LoLBench with your own agent

LoLBench tasks are plain [Harbor](https://github.com/jasonlim-cerberus/swebenchpro-harbor)
tasks, so any agent Harbor can drive works. `harbor run -a <agent>` accepts three
forms:

1. **Built-in agent** — `-a opencode | codex | claude-code | aider | mini-swe-agent | …`
   (see `harbor run --help`). This is the reference path.
2. **ACP shorthand** — `-a acp:<agent>@<version>` (e.g. `acp:opencode@1.3.9`), for
   any agent that speaks the [Agent Client Protocol](https://agentclientprotocol.com/).
   Lowest effort **if** your agent ships an ACP server.
3. **Custom adapter class** — `-a your.module:ClassName`. Write a small Python
   class that subclasses Harbor's `BaseInstalledAgent` (the base `opencode` uses),
   make it importable, and pass its import path. This is the general path for any
   CLI/library agent.

## The `BaseInstalledAgent` contract

`BaseInstalledAgent` (which extends `BaseAgent`) is the base for CLI agents that
install themselves. You override four methods (inspect your installed version with
`uv run --with harbor python -c "import inspect, harbor.agents.installed.base as b; print(inspect.getsource(b.BaseInstalledAgent))"`):

| Method | Responsibility |
|--------|----------------|
| `name()` | the agent's short name |
| `get_version_command()` | a shell command that verifies the install (or `None`) |
| `install(environment)` | install the agent + tooling in the container; write its config |
| `run(instruction, environment, context)` | solve the task, then **submit the patch** |

Key facilities the base class gives you:

- **`self.model_connection`** resolves the provider from `-m <provider>/<model>`:
  its `.env` carries the API key (e.g. `OPENROUTER_API_KEY`) and `.configured_base_url`
  the endpoint. You pass these to your agent — no hard-coded keys.
- **Network phases.** The install/setup phase runs with the network your agent
  needs to install itself. The `run()` phase is restricted to the task's **agent allowlist**
  (`openrouter.ai`, `api.openai.com`, `api.anthropic.com` — see
  [ANTI_CHEAT.md](ANTI_CHEAT.md)); your agent can reach the model but not source
  hosts.
- **Submitting.** The verifier grades `/logs/artifacts/solution.patch`, produced by
  the in-container **`lolbench-submit`** command (it captures the working-tree diff,
  excluding test paths). Every task's `instruction.md` tells the agent to run it;
  a robust adapter also calls `lolbench-submit` itself at the end of `run()`.

## Worked example: Chrys

[`agents/chrys_agent.py`](agents/chrys_agent.py) is a reference adapter for
[Chrys](https://github.com/0x7c13/chrys). It mirrors how LoLBench runs Chrys
natively:

- **`install()`** — `git clone` Chrys, `uv python install 3.14 && uv sync --extra all`,
  and write an OpenRouter model profile whose `model_id` comes from `self.model_name`
  and whose key is `{{OPENROUTER_API_KEY}}` (resolved from `self.model_connection.env`).
- **`run()`** — write the instruction to a file and call `chrys run --task <file>
  --agent Code --workdir <repo> --json`, then `lolbench-submit`. The repo lives at
  `/workspace/<project>` (e.g. `/workspace/ruff` for `ruff_1`), so point `--workdir`
  at the actual checkout.

Run it:

```bash
export OPENROUTER_API_KEY=sk-or-...
PYTHONPATH=. harbor run \
  -p harbor_tasks/ruff_1 \
  -a agents.chrys_agent:ChrysAgent \
  -m openrouter/deepseek/deepseek-v4-pro \
  --job-name ruff_1_chrys --jobs-dir harbor_runs/ruff_1 \
  --no-delete -n 1 -y \
  --ve LOLBENCH_SUITE=union

cat harbor_runs/ruff_1/ruff_1_chrys/*/verifier/reward.json
```

### Anti-cheat notes for custom agents

- **Reach only the model.** If your agent needs an endpoint other than the three
  allowlisted hosts, add **only** that host with `--allow-agent-host <host>` —
  never a source host (`github.com`, `pypi.org`, package mirrors, Maven Central).
- **Mind your agent's own runtime.** The eval image strips whole-module
  deliverables (`tomllib` = PEP 680, `zoneinfo` = PEP 615) from the *system*
  Python, but an agent that ships its **own** interpreter (Chrys uses uv Python)
  reintroduces them. The reference adapter removes `tomllib` (a deliverable) and the
  CPython `test` package from Chrys's Python in `install()` for this reason; add
  `zoneinfo` too if you run the PEP-615 task (`cpython_2`) with such an agent.
- **Give it time.** These are long-horizon tasks; the default agent-run budget is
  6 h (`task.toml` `[agent] timeout_sec`). Keep timeout multipliers ≥ 1 (a value
  < 1 also shrinks the setup budget and causes `AgentSetupTimeoutError`).

> The Chrys adapter is a **template**: exact `BaseInstalledAgent`/`BaseEnvironment`
> method names can differ across Harbor versions, and the install/timeouts may need
> tuning for your model. Validate it on one task (`ruff_1`) before a full sweep.

# Reproducing LoLBench

Step-by-step instructions to run any LoLBench task through
[Harbor](https://github.com/jasonlim-cerberus/swebenchpro-harbor) and read the
graded reward. Every command below is copy-paste runnable from the repository
root.

## 1. Prerequisites

- **Docker** (with enough disk — task images are 2–17 GB each; budget ~150 GB to
  run all 20). A running Docker daemon is required.
- **[uv](https://docs.astral.sh/uv/)** or `pipx` to install the Harbor CLI.
- A **model API key**. The reference setting uses **OpenRouter**; any provider
  Harbor supports works (see [below](#choosing-an-agent--model)).

## 2. Install Harbor

```bash
uv tool install harbor          # or: pipx install harbor
harbor --version                # validated with 0.21.x
```

This installs the `harbor` CLI (aliases `hb`, `hr`).

## 3. Configure your API key

```bash
export OPENROUTER_API_KEY=sk-or-...        # https://openrouter.ai/keys
```

Harbor's `openrouter` provider reads `OPENROUTER_API_KEY` from the environment
and forwards it to the agent container. Other providers read their own key
(`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, …).

> Harbor does **not** auto-load a `.env` file. `cp .env.example .env` and editing
> it only works with the wrapper scripts in [§8](#8-run-all-20-tasks-in-parallel)
> (they source `.env`); for a direct `harbor run`, `export` the key as above or
> pass `--env-file .env`.

## 4. Understand the reward

Each trial writes `verifier/reward.json`:

```json
{ "applied": 1.0, "build_ok": 1.0, "f2p_pass_rate": 1.0,
  "harness_ok": 1.0, "p2p_pass_rate": 1.0, "resolved": 1.0, "reward": 1.0 }
```

`reward = 1.0` **iff** the patch applied, the project built, and **all** F2P and
P2P tests passed (`resolved`). Anything less is `reward = 0.0`. The full grader
detail is alongside it in `verifier/agent_report.json`.

## 5. Oracle parity check (validate a task)

Before trusting a task, confirm its **gold** patch resolves. The `oracle` agent
applies `solution/solve.sh` and must score `reward = 1.0`:

```bash
harbor run \
  -p harbor_tasks/ruff_1 \
  -a oracle \
  --job-name ruff_1_oracle --jobs-dir harbor_runs/ruff_1 \
  --no-delete -n 1 -y \
  --ve LOLBENCH_SUITE=union

cat harbor_runs/ruff_1/ruff_1_oracle/*/verifier/reward.json    # expect reward 1.0
```

## 6. Run an agent on one task

Reference setting — **OpenCode + DeepSeek-V4-Pro via OpenRouter**:

```bash
harbor run \
  -p harbor_tasks/ruff_1 \
  -a opencode \
  -m openrouter/deepseek/deepseek-v4-pro \
  --job-name ruff_1_run --jobs-dir harbor_runs/ruff_1 \
  --no-delete -n 1 -y \
  --ve LOLBENCH_SUITE=union

cat harbor_runs/ruff_1/ruff_1_run/*/verifier/reward.json
```

The agent implements the feature in the container, then `lolbench-submit`
captures its working-tree diff; the verifier grades that diff.

## 7. Suite modes

Select the test suite with `--ve LOLBENCH_SUITE=<mode>` (default `union`):

| Mode    | Tests |
|---------|-------|
| `orig`  | the PR's own F2P/P2P tests at the gold commit (headline) |
| `aug`   | an augmented, mutation-hardened set targeting the same change |
| `union` | `orig ∪ aug` — the strict verdict (recommended) |

## 8. Run all 20 tasks in parallel

Use the wrapper, which runs the whole suite with a bounded number of tasks in
flight (default 4):

```bash
export OPENROUTER_API_KEY=sk-or-...
scripts/run_all.sh opencode openrouter/deepseek/deepseek-v4-pro union 4
#                  ^agent   ^model                                 ^suite ^parallelism
```

It writes each task's job under `harbor_runs/<id>/` and prints a reward summary
at the end. To run a single task with the same defaults:

```bash
scripts/run_task.sh ruff_1 opencode openrouter/deepseek/deepseek-v4-pro union
```

Or drive Harbor directly across tasks yourself. Note this loop is **sequential**
(one task at a time) — for concurrency across tasks use `run_all.sh`'s parallelism
argument above; Harbor's own `-n` only controls concurrency **within** a single job:

```bash
for t in harbor_tasks/*/; do
  id=$(basename "$t")
  harbor run -p "$t" -a opencode -m openrouter/deepseek/deepseek-v4-pro \
    --job-name "${id}_run" --jobs-dir "harbor_runs/${id}" --no-delete -n 1 -y \
    --ve LOLBENCH_SUITE=union
done
```

## 9. Collect results

```bash
python3 - <<'PY'
import json, glob
for p in sorted(glob.glob("harbor_runs/**/verifier/reward.json", recursive=True)):
    print(json.load(open(p))["reward"], p)
PY
```

Or browse trajectories interactively: `harbor view harbor_runs/<id>`.

## Choosing an agent & model

`harbor run -a <agent> -m <provider>/<model>`:

- **Agents** (`harbor run --help` lists all): `opencode`, `codex`, `claude-code`,
  `aider`, `mini-swe-agent`, `terminus`, … plus `oracle` (gold) and `nop` (no-op).
- **Models** use `provider/model` form. Via OpenRouter:
  `openrouter/deepseek/deepseek-v4-pro`, `openrouter/openai/gpt-5.5`,
  `openrouter/anthropic/claude-opus-4.8`, etc. Native providers:
  `deepseek/deepseek-v4-pro` (with `DEEPSEEK_API_KEY`), `openai/...`,
  `anthropic/...`.

The agent-phase network allowlist permits `openrouter.ai`, `api.openai.com`, and
`api.anthropic.com` (see [ANTI_CHEAT.md](ANTI_CHEAT.md)). To reach any other
model endpoint, add `--allow-agent-host <host>` — **only** the model host, never
a source host.

**Your own agent** (not one of Harbor's built-ins — e.g. Chrys): write a small
`BaseInstalledAgent` adapter and run `-a your.module:ClassName`. Full walkthrough +
reference adapter in [CUSTOM_AGENT.md](CUSTOM_AGENT.md).

## Evaluating a pre-made patch (no agent)

To grade a patch you produced elsewhere, mount it and let the `oracle` apply it:

```bash
PATCH="$(pwd)/my_solution.patch"
harbor run -p harbor_tasks/ruff_1 -a oracle \
  --job-name ruff_1_eval --jobs-dir harbor_runs/ruff_1 --no-delete -n 1 -y \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

## Troubleshooting

- **First run is slow** — Harbor pulls a multi-GB image and builds a one-time
  network-egress sidecar. Subsequent runs reuse both.
- **Image pull fails** — build locally instead:
  `docker build -t smartdub26/lolbench:<id>-1.0.0 harbor_tasks/<id>/environment`
  (needs the language base image; slow).
- **Agent can't reach the model** — confirm the key env var is exported in the
  shell that runs `harbor`, and that the host is allowlisted (the three defaults,
  or add `--allow-agent-host`).
- **Transient model/network error mid-run** — occasional TLS/network hiccups on a
  model call (e.g. an intermittent certificate-verification error) can fail an
  otherwise-good trial. Add `--max-retries N` (`-r`) for robustness; retries are
  off by default. A litellm warning about fetching a cost map from `github.com` is
  harmless — github is intentionally blocked and litellm falls back to a bundled map.
- **Agent run timeout** — each task allows a long-horizon budget by default
  (`task.toml` `[agent] timeout_sec`, **21600 s = 6 h** for most tasks); the setup
  (tooling install) budget is 3600 s. Scale either with
  `--agent-timeout-multiplier <f>` / `--agent-setup-timeout-multiplier <f>`
  (e.g. `2.0` → 12 h run; **avoid values < 1**, which can starve the agent's
  install step and cause `AgentSetupTimeoutError`).

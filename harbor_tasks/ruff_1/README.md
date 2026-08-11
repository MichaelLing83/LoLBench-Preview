# LoLBench Harbor Task: ruff_1

This is a Harbor-format LoLBench task generated from `Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599`.

Selected source instance:

- Harbor ID: `ruff_1`
- Docker bundle: `dockers/Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599`
- PR: `astral-sh/ruff#9599`
- Base commit: `b21ba71ef4b897cbb9e3c402f081887b650b6448`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:ruff_1-1.0.0`
- Docker Hub image: `smartdub26/lolbench:ruff_1-1.0.0`
- Docker Hub digest: `sha256:67c0c3dc371a960118442b10e971b7785fae9420e0c73de8c4445321ae025f17`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:ruff_1-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:ruff_1-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/ruff_1:1.0.0 harbor_tasks/ruff_1/environment
docker tag lolbench/ruff_1:1.0.0 smartdub26/lolbench:ruff_1-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/ruff`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/ruff_1 \
  -a codex \
  -m "<model>" \
  --job-name ruff_1_agent_union \
  --jobs-dir harbor_runs/ruff_1 \
  --no-delete \
  --n-concurrent 1 \
  --ve LOLBENCH_SUITE=union
```

After implementing the requirement, the agent must clean any test-file edits
and run:

```bash
lolbench-submit
```

## Evaluate a Patch

Choose one mode with `LOLBENCH_SUITE=orig`, `aug`, or `union`; if unset, the
task defaults to `union`.

```bash
PATCH="$(pwd)/path/to/solution.patch"

.harbor-venv/bin/harbor run \
  -p harbor_tasks/ruff_1 \
  -a oracle \
  --job-name ruff_1_eval_union \
  --jobs-dir harbor_runs/ruff_1 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/ruff_1/ruff_1_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/ruff_1/ruff_1_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

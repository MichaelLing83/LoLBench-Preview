# LoLBench Harbor Task: flink_1

This is a Harbor-format LoLBench task generated from `Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976`.

Selected source instance:

- Harbor ID: `flink_1`
- Docker bundle: `dockers/Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976`
- PR: `apache/flink#9976`
- Base commit: `005bda9be361ffe6c371ebefed32e614cbacd876`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:flink_1-1.0.0`
- Docker Hub image: `smartdub26/lolbench:flink_1-1.0.0`
- Docker Hub digest: `sha256:74d54be14889a973d6ad90a47aa664312bb8fcf8dbe2d384d0918ec34b3651c2`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:flink_1-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:flink_1-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/flink_1:1.0.0 harbor_tasks/flink_1/environment
docker tag lolbench/flink_1:1.0.0 smartdub26/lolbench:flink_1-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/flink`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/flink_1 \
  -a codex \
  -m "<model>" \
  --job-name flink_1_agent_union \
  --jobs-dir harbor_runs/flink_1 \
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
  -p harbor_tasks/flink_1 \
  -a oracle \
  --job-name flink_1_eval_union \
  --jobs-dir harbor_runs/flink_1 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/flink_1/flink_1_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/flink_1/flink_1_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

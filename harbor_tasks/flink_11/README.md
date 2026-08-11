# LoLBench Harbor Task: flink_11

This is a Harbor-format LoLBench task generated from `Apache-Flink_FLIP-498_AsyncTableFunction-for-async-table-function-support_PR-26567`.

Selected source instance:

- Harbor ID: `flink_11`
- Docker bundle: `dockers/Apache-Flink_FLIP-498_AsyncTableFunction-for-async-table-function-support_PR-26567`
- PR: `apache/flink#26567`
- Base commit: `7309fe832cb303c9adf6bfb441790e3d293908fe`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:flink_11-1.0.0`
- Docker Hub image: `smartdub26/lolbench:flink_11-1.0.0`
- Docker Hub digest: `sha256:059d8f0d8a94d573671531d0c189ae35c6b826a5278f907ca48659706db70e0c`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:flink_11-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:flink_11-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/flink_11:1.0.0 harbor_tasks/flink_11/environment
docker tag lolbench/flink_11:1.0.0 smartdub26/lolbench:flink_11-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/flink`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/flink_11 \
  -a codex \
  -m "<model>" \
  --job-name flink_11_agent_union \
  --jobs-dir harbor_runs/flink_11 \
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
  -p harbor_tasks/flink_11 \
  -a oracle \
  --job-name flink_11_eval_union \
  --jobs-dir harbor_runs/flink_11 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/flink_11/flink_11_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/flink_11/flink_11_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

# LoLBench Harbor Task: fastapi_1

This is a Harbor-format LoLBench task generated from `FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871`.

Selected source instance:

- Harbor ID: `fastapi_1`
- Docker bundle: `dockers/FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871`
- PR: `fastapi/fastapi#4871`
- Base commit: `ef176c663195489b44030bfe1fb94a317762c8d5`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:fastapi_1-1.0.0`
- Docker Hub image: `smartdub26/lolbench:fastapi_1-1.0.0`
- Docker Hub digest: `sha256:f895fc6938db9c627e8ca3e05b3463099f713e6b1f3435d1a8f5d14c4675b6d2`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:fastapi_1-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:fastapi_1-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/fastapi_1:1.0.0 harbor_tasks/fastapi_1/environment
docker tag lolbench/fastapi_1:1.0.0 smartdub26/lolbench:fastapi_1-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/fastapi`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/fastapi_1 \
  -a codex \
  -m "<model>" \
  --job-name fastapi_1_agent_union \
  --jobs-dir harbor_runs/fastapi_1 \
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
  -p harbor_tasks/fastapi_1 \
  -a oracle \
  --job-name fastapi_1_eval_union \
  --jobs-dir harbor_runs/fastapi_1 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/fastapi_1/fastapi_1_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/fastapi_1/fastapi_1_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

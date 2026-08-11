# LoLBench Harbor Task: cpython_9

This is a Harbor-format LoLBench task generated from `CPython_PEP-709_Inlined-comprehensions_PR-101441`.

Selected source instance:

- Harbor ID: `cpython_9`
- Docker bundle: `dockers/CPython_PEP-709_Inlined-comprehensions_PR-101441`
- PR: `python/cpython#101441`
- Base commit: `0aeda297931820436a50b78f4f7f0597274b5df4`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:cpython_9-1.0.0`
- Docker Hub image: `smartdub26/lolbench:cpython_9-1.0.0`
- Docker Hub digest: `sha256:5c45261b498fb39a40fd838e08b0c62d16e8f7da1ff6675aed2d22a815f7759f`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:cpython_9-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:cpython_9-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/cpython_9:1.0.0 harbor_tasks/cpython_9/environment
docker tag lolbench/cpython_9:1.0.0 smartdub26/lolbench:cpython_9-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/cpython`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/cpython_9 \
  -a codex \
  -m "<model>" \
  --job-name cpython_9_agent_union \
  --jobs-dir harbor_runs/cpython_9 \
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
  -p harbor_tasks/cpython_9 \
  -a oracle \
  --job-name cpython_9_eval_union \
  --jobs-dir harbor_runs/cpython_9 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/cpython_9/cpython_9_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/cpython_9/cpython_9_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

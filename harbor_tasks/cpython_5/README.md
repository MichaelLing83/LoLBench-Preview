# LoLBench Harbor Task: cpython_5

This is a Harbor-format LoLBench task generated from `CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498`.

Selected source instance:

- Harbor ID: `cpython_5`
- Docker bundle: `dockers/CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498`
- PR: `python/cpython#31498`
- Base commit: `0b5a573ce8e8e90daad4d24b215aabb7356f4fce`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:cpython_5-1.0.0`
- Docker Hub image: `smartdub26/lolbench:cpython_5-1.0.0`
- Docker Hub digest: `sha256:81c5d064616ed245b2680fe2b437f0d0264482c16734c5b76b2ad376c1ceea65`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:cpython_5-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:cpython_5-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/cpython_5:1.0.0 harbor_tasks/cpython_5/environment
docker tag lolbench/cpython_5:1.0.0 smartdub26/lolbench:cpython_5-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/cpython`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/cpython_5 \
  -a codex \
  -m "<model>" \
  --job-name cpython_5_agent_union \
  --jobs-dir harbor_runs/cpython_5 \
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
  -p harbor_tasks/cpython_5 \
  -a oracle \
  --job-name cpython_5_eval_union \
  --jobs-dir harbor_runs/cpython_5 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/cpython_5/cpython_5_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/cpython_5/cpython_5_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

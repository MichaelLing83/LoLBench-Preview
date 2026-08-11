# LoLBench Harbor Task: cpython_2

This is a Harbor-format LoLBench task for CPython PEP 615.

Selected source instance:

- Harbor ID: `cpython_2`
- Docker bundle: `dockers/CPython_PEP-615_Support-for-the-IANA-Time-Zone-Database-in-the-Standard-Library_PR-19909`
- PR: `python/cpython#19909`
- Base commit: `6e8cda91d92da72800d891b2fc2073ecbc134d98`
- Test modes: `orig`, `aug`, `union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:cpython_2-1.0.0`
- Docker Hub image: `smartdub26/lolbench:cpython_2-1.0.0`
- Docker Hub digest: `sha256:629883723cc0b9e8b1b9f2f9b3f95f1dd993086a8fc06c05a12b3ce4ce48cee9`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:cpython_2-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:cpython_2-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/cpython_2:1.0.0 harbor_tasks/cpython_2/environment
docker tag lolbench/cpython_2:1.0.0 smartdub26/lolbench:cpython_2-1.0.0
```

The image contains the entire processed CPython source tree at the base commit
under `/workspace/cpython`; Harbor must not mount a host source checkout for
the agent.

The agent and verifier both use this same image. Private verifier files are not
baked into the image; Harbor mounts them only in the separate verifier phase.

## Run an Agent

Use Harbor to run an agent. Replace the agent and model with the evaluation
configuration you want.

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/cpython_2 \
  -a codex \
  -m "<model>" \
  --job-name cpython_2_agent_union \
  --jobs-dir harbor_runs/cpython_2 \
  --no-delete \
  --n-concurrent 1 \
  --ve LOLBENCH_SUITE=union
```

The agent works in:

```bash
/workspace/cpython
```

After implementing the requirement, the agent must run:

```bash
lolbench-submit
```

This writes:

```text
/logs/artifacts/solution.patch
```

On the host, that patch is available at:

```bash
find harbor_runs/cpython_2/cpython_2_agent_union -path '*/artifacts/solution.patch' -print
```

## Evaluate a Patch

The verifier consumes `/logs/artifacts/solution.patch` and writes a sanitized
report plus reward. Choose one mode with `LOLBENCH_SUITE=orig`, `aug`, or
`union`; if unset, the task defaults to `union`. To evaluate an existing patch
through Harbor, run the oracle agent as a patch loader and mount the candidate
patch into the agent container:

```bash
PATCH="$(pwd)/path/to/solution.patch"

.harbor-venv/bin/harbor run \
  -p harbor_tasks/cpython_2 \
  -a oracle \
  --job-name cpython_2_eval_union \
  --jobs-dir harbor_runs/cpython_2 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/cpython_2/cpython_2_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/cpython_2/cpython_2_eval_union -path '*/verifier/reward.json' -print
```

Use `LOLBENCH_SUITE=orig` or `LOLBENCH_SUITE=aug` with separate output
job names to evaluate the other modes.

## Notes

The source in `environment/repo/` is an archived base-commit snapshot. It does
not contain CPython's original `.git` directory. During build, the Dockerfile
first removes any `/workspace/cpython` checkout inherited from the base image,
then copies this snapshot and creates a fresh local git repository with a single
synthetic base commit. Agents can produce a normal patch without seeing or
recovering later upstream commits through git.

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

`solution/solution.patch` is the maintainer oracle patch for validation. Do not
mount it into agent containers.

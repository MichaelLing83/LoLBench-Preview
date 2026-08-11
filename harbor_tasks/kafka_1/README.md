# LoLBench Harbor Task: kafka_1

This is a Harbor-format LoLBench task generated from `Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378`.

Selected source instance:

- Harbor ID: `kafka_1`
- Docker bundle: `dockers/Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378`
- PR: `apache/kafka#7378`
- Base commit: `0de61a4683b92bdee803c51211c3277578ab3edf`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:kafka_1-1.0.0`
- Docker Hub image: `smartdub26/lolbench:kafka_1-1.0.0`
- Docker Hub digest: `sha256:f43a70d113e7f80ee0e30f8d502e02e68be3b563ed40d7286d040f3987274583`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:kafka_1-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:kafka_1-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/kafka_1:1.0.0 harbor_tasks/kafka_1/environment
docker tag lolbench/kafka_1:1.0.0 smartdub26/lolbench:kafka_1-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/kafka`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/kafka_1 \
  -a codex \
  -m "<model>" \
  --job-name kafka_1_agent_union \
  --jobs-dir harbor_runs/kafka_1 \
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
  -p harbor_tasks/kafka_1 \
  -a oracle \
  --job-name kafka_1_eval_union \
  --jobs-dir harbor_runs/kafka_1 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/kafka_1/kafka_1_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/kafka_1/kafka_1_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

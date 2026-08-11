# LoLBench Harbor Task: kafka_2

This is a Harbor-format LoLBench task generated from `Apache-Kafka_KIP-769-Connect-APIs-to-list-all-connector-plugins-and-retri_PR-11572`.

Selected source instance:

- Harbor ID: `kafka_2`
- Docker bundle: `dockers/Apache-Kafka_KIP-769-Connect-APIs-to-list-all-connector-plugins-and-retri_PR-11572`
- PR: `apache/kafka#11572`
- Base commit: `066cdc8c621dfc4d26e12ee539368d6c1eb2707f`
- Test modes: `orig, aug, union`
- Default/canonical mode: `union`
- Harbor image: `smartdub26/lolbench:kafka_2-1.0.0`
- Docker Hub image: `smartdub26/lolbench:kafka_2-1.0.0`
- Docker Hub digest: `sha256:368ffd392be3be9cbeb107b42809a165b2ae8001f9abf3a244eb8da059d719ef`

## Image Setup

Prefer the published Docker Hub image when it is available. Harbor refers to
the image as `smartdub26/lolbench:kafka_2-1.0.0`, so Docker can pull it
directly when it is not present locally:

```bash
docker pull smartdub26/lolbench:kafka_2-1.0.0
```

Only if the Docker Hub image is unavailable, build the single task image
locally:

```bash
docker build -t lolbench/kafka_2:1.0.0 harbor_tasks/kafka_2/environment
docker tag lolbench/kafka_2:1.0.0 smartdub26/lolbench:kafka_2-1.0.0
```

The image contains the processed source tree at the base commit under
`/workspace/kafka`. Harbor must not mount a host source checkout
for the agent.

## Run an Agent

```bash
.harbor-venv/bin/harbor run \
  -p harbor_tasks/kafka_2 \
  -a codex \
  -m "<model>" \
  --job-name kafka_2_agent_union \
  --jobs-dir harbor_runs/kafka_2 \
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
  -p harbor_tasks/kafka_2 \
  -a oracle \
  --job-name kafka_2_eval_union \
  --jobs-dir harbor_runs/kafka_2 \
  --no-delete \
  --n-concurrent 1 \
  --mounts '[{"type":"bind","source":"'"$PATCH"'","target":"/candidate/solution.patch","read_only":true}]' \
  --ae LOLBENCH_ORACLE_PATCH=/candidate/solution.patch \
  --ve LOLBENCH_SUITE=union
```

Outputs:

```bash
find harbor_runs/kafka_2/kafka_2_eval_union -path '*/verifier/agent_report.json' -print
find harbor_runs/kafka_2/kafka_2_eval_union -path '*/verifier/reward.json' -print
```

`tests/docker-compose.yaml` is a verifier-only Harbor overlay. It mounts
`tests/`, `tests/private/`, and `solution/` into the separate verifier
container; none of those paths are mounted into the agent container.

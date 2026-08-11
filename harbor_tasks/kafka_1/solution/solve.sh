#!/usr/bin/env bash
set -euo pipefail

cd /workspace/kafka
patch=${LOLBENCH_ORACLE_PATCH:-/solution/solution.patch}
git apply "$patch"
lolbench-submit

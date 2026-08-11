#!/usr/bin/env bash
set -euo pipefail

suite=${LOLBENCH_SUITE:-union}
mode=${LOLBENCH_MODE:-eval}
patch=${LOLBENCH_SOLUTION_PATCH:-/logs/artifacts/solution.patch}
private_log=/tmp/lolbench-private-run.log

mkdir -p /logs/verifier /logs/artifacts /in /out

case "$suite" in
    orig|aug|union) ;;
    *)
        python3 /tests/report_to_reward.py \
            --suite "$suite" \
            --invalid-suite \
            /out/agent_report.json \
            /logs/verifier/reward.json
        exit 0
        ;;
esac

if [ "$mode" = "eval" ] && [ ! -s "$patch" ]; then
    python3 /tests/report_to_reward.py \
        --suite "$suite" \
        --missing-patch "$patch" \
        /out/agent_report.json \
        /logs/verifier/reward.json
    exit 0
fi

if [ "$mode" = "eval" ]; then
    cp "$patch" /in/solution.patch
    chmod 0400 /in/solution.patch
fi

set +e
LOLBENCH_MODE="$mode" \
LOLBENCH_SUITE="$suite" \
    /opt/lolbench/private/run_tests.sh >"$private_log" 2>&1
runner_rc=$?
set -e

cp "$private_log" /logs/verifier/private_run.log
if [ -f /out/grader_report.json ]; then
    cp /out/grader_report.json /logs/verifier/grader_report.json
fi

python3 /tests/report_to_reward.py \
    --suite "$suite" \
    --runner-rc "$runner_rc" \
    /out/agent_report.json \
    /logs/verifier/reward.json

if [ -f /out/agent_report.json ]; then
    cp /out/agent_report.json /logs/verifier/agent_report.json
fi

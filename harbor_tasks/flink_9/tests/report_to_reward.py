#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def rate(bucket):
    total = float(bucket.get("total", 0) or 0)
    if total <= 0:
        return 0.0
    return float(bucket.get("passed", 0) or 0) / total


def write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite", default="union")
    parser.add_argument("--missing-patch")
    parser.add_argument("--invalid-suite", action="store_true")
    parser.add_argument("--runner-rc", type=int, default=0)
    parser.add_argument("agent_report")
    parser.add_argument("reward_file")
    args = parser.parse_args()

    report_path = Path(args.agent_report)
    reward_path = Path(args.reward_file)

    if args.invalid_suite:
        reward = {"reward": 0.0, "resolved": 0.0, "applied": 0.0, "build_ok": 0.0, "f2p_pass_rate": 0.0, "p2p_pass_rate": 0.0, "harness_ok": 1.0}
        sanitized = {"instance_id": "flink_9", "suite": args.suite, "applied": False, "resolved": False, "error_categories": ["invalid_lolbench_suite"]}
        write_json(report_path, sanitized)
        write_json(reward_path, reward)
        print(f"LoLBench reward=0 invalid suite {args.suite!r}")
        return 0

    if args.missing_patch:
        reward = {"reward": 0.0, "resolved": 0.0, "applied": 0.0, "build_ok": 0.0, "f2p_pass_rate": 0.0, "p2p_pass_rate": 0.0, "harness_ok": 1.0}
        sanitized = {"instance_id": "flink_9", "suite": args.suite, "applied": False, "resolved": False, "error_categories": ["missing_solution_patch"]}
        write_json(report_path, sanitized)
        write_json(reward_path, reward)
        print("LoLBench reward=0 missing solution patch")
        return 0

    if not report_path.exists():
        reward = {"reward": 0.0, "resolved": 0.0, "applied": 0.0, "build_ok": 0.0, "f2p_pass_rate": 0.0, "p2p_pass_rate": 0.0, "harness_ok": 0.0}
        write_json(reward_path, reward)
        print(f"LoLBench reward=0 no agent_report.json runner_rc={args.runner_rc}")
        return 0

    report = json.loads(report_path.read_text())
    build_status = report.get("build", {}).get("status")
    resolved = bool(report.get("resolved"))
    applied = bool(report.get("applied"))
    reward = {
        "reward": 1.0 if resolved else 0.0,
        "resolved": 1.0 if resolved else 0.0,
        "applied": 1.0 if applied else 0.0,
        "build_ok": 1.0 if build_status == "ok" else 0.0,
        "f2p_pass_rate": rate(report.get("f2p", {})),
        "p2p_pass_rate": rate(report.get("p2p", {})),
        "harness_ok": 1.0 if args.runner_rc == 0 else 0.0,
    }
    write_json(reward_path, reward)
    print("LoLBench reward={reward} resolved={resolved} f2p={f2p_pass_rate:.3f} p2p={p2p_pass_rate:.3f}".format(**reward))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Reconstruct solution/eval/omitted patches for FLIP-467 PR-25731.

The split follows docs/executable_environment_plan.md:

* solution.patch: production source, build files, generated/source support.
* eval_tests.patch: only the selected system-level F2P test file.
* omitted.patch: non-selected unit/helper/baseline test hunks and documentation.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent
SLUG = "Apache-Flink_FLIP-467-Introduce-Generalized-Watermarks_PR-25731"
CACHE = REPO_ROOT / "data" / "pr_files_cache" / f"{SLUG}.json"
SELECTED_EVAL_TEST_FILES = {
    "flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/WatermarkITCase.java",
}


def categorize(filename: str) -> str:
    if filename in SELECTED_EVAL_TEST_FILES:
        return "eval_tests"
    if "/src/test/" in filename:
        return "omitted"
    if filename.startswith("flink-architecture-tests/"):
        return "omitted"
    if filename.endswith("/log4j2-test.properties"):
        return "omitted"
    if filename.endswith(".md") or filename.startswith("docs/"):
        return "omitted"
    return "solution"


def render(entry: dict) -> str:
    filename = entry["filename"]
    status = entry["status"]
    patch = entry.get("patch", "")
    if not patch:
        raise ValueError(f"empty patch body for {filename}")

    lines = [f"diff --git a/{filename} b/{filename}"]
    if status == "added":
        lines.extend(["new file mode 100644", "--- /dev/null", f"+++ b/{filename}"])
    elif status == "removed":
        lines.extend(["deleted file mode 100644", f"--- a/{filename}", "+++ /dev/null"])
    elif status == "renamed":
        raise ValueError(f"unexpected rename in cached diff: {filename}")
    else:
        lines.extend([f"--- a/{filename}", f"+++ b/{filename}"])

    block = "\n".join(lines) + "\n" + patch
    return block if block.endswith("\n") else block + "\n"


def main() -> int:
    entries = json.loads(CACHE.read_text())
    buckets = {"solution": [], "eval_tests": [], "omitted": []}
    audit = {"solution": [], "eval_tests": [], "omitted": []}

    for entry in entries:
        role = categorize(entry["filename"])
        buckets[role].append(render(entry))
        audit[role].append(entry["filename"])

    for role in ("solution", "eval_tests", "omitted"):
        body = "".join(buckets[role])
        (HERE / f"{role}.patch").write_text(body)
        print(f"{role}.patch: {len(audit[role])} files, {len(body):,} bytes")

    total = sum(len(v) for v in audit.values())
    print(f"Total: {total} files (cache has {len(entries)})")
    if total != len(entries):
        return 1
    for role in ("solution", "eval_tests", "omitted"):
        print(f"\n[{role}]")
        for filename in audit[role]:
            print(filename)
    return 0


if __name__ == "__main__":
    sys.exit(main())

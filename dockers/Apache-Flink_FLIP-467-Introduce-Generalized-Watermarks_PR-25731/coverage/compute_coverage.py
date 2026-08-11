#!/usr/bin/env python3
"""Compute JaCoCo line coverage for FLIP-467 solution.patch."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


SOURCE_ROOTS = [
    "flink-core-api/src/main/java",
    "flink-core/src/main/java",
    "flink-datastream-api/src/main/java",
    "flink-datastream/src/main/java",
    "flink-libraries/flink-state-processing-api/src/main/java",
    "flink-runtime/src/main/java",
    "flink-streaming-java/src/main/java",
    "flink-table/flink-table-runtime/src/main/java",
    "flink-tests/src/main/java",
]


def parse_patched_lines(patch_path: str) -> dict[str, set[int]]:
    out: dict[str, set[int]] = defaultdict(set)
    cur = None
    new_line = None
    for raw in open(patch_path):
        line = raw.rstrip("\n")
        m = re.match(r"^diff --git a/(.*) b/(.*)$", line)
        if m:
            cur = m.group(2)
            new_line = None
            continue
        if cur is None:
            continue
        m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if m:
            new_line = int(m.group(1))
            continue
        if new_line is None:
            continue
        if line.startswith("+++"):
            continue
        if line.startswith("+"):
            out[cur].add(new_line)
            new_line += 1
        elif line.startswith("-"):
            pass
        elif line.startswith(" ") or line == "":
            new_line += 1
    return dict(out)


def classify(path: str) -> str:
    return "java" if path.endswith(".java") else "other"


def load_jacoco_xml(xml_path: str) -> tuple[dict[str, tuple[set[int], set[int]]], dict]:
    if not os.path.exists(xml_path) or os.path.getsize(xml_path) == 0:
        return {}, {"ok": False, "error": f"no/empty XML at {xml_path}"}
    try:
        root = ET.parse(xml_path).getroot()
    except ET.ParseError as exc:
        return {}, {"ok": False, "error": f"XML parse: {exc}"}

    out: dict[str, tuple[set[int], set[int]]] = {}
    for pkg in root.findall("package"):
        pkg_name = pkg.attrib.get("name", "")
        for source in pkg.findall("sourcefile"):
            name = source.attrib.get("name", "")
            if not name:
                continue
            executable: set[int] = set()
            executed: set[int] = set()
            for line in source.findall("line"):
                nr = int(line.attrib.get("nr", 0))
                mi = int(line.attrib.get("mi", 0))
                ci = int(line.attrib.get("ci", 0))
                if mi + ci == 0:
                    continue
                executable.add(nr)
                if ci > 0:
                    executed.add(nr)
            suffix = str(Path(pkg_name) / name) if pkg_name else name
            for root_dir in SOURCE_ROOTS:
                out[str(Path(root_dir) / suffix)] = (executed, executable)
    return out, {"ok": True, "error": None}


def pct(num: int, den: int) -> float | None:
    return round(100 * num / den, 1) if den else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--solution-patch", required=True)
    parser.add_argument("--flink-root", required=True)
    parser.add_argument("--f2p-xml", required=True)
    parser.add_argument("--p2p-xml", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    patched = parse_patched_lines(args.solution_patch)
    f2p_map, f2p_status = load_jacoco_xml(args.f2p_xml)
    p2p_map, p2p_status = load_jacoco_xml(args.p2p_xml)
    tool_status = {"f2p_jacoco": f2p_status, "p2p_jacoco": p2p_status}
    coverage_complete = all(status.get("ok") for status in tool_status.values())

    files_report = {}
    total_added = total_executable = total_f2p = total_p2p = total_union = 0
    for rel, lines in sorted(patched.items()):
        kind = classify(rel)
        if kind != "java":
            files_report[rel] = {
                "kind": kind,
                "lines_in_patch": len(lines),
                "note": "skipped: not a measurable Java source file",
            }
            continue

        f2p_exec, f2p_able = f2p_map.get(rel, (set(), set()))
        p2p_exec, p2p_able = p2p_map.get(rel, (set(), set()))
        executable_added = lines & (f2p_able | p2p_able)
        f2p_hit = executable_added & f2p_exec
        p2p_hit = executable_added & p2p_exec
        union_hit = f2p_hit | p2p_hit
        denom = len(executable_added)

        files_report[rel] = {
            "kind": kind,
            "lines_in_patch": len(lines),
            "executable_lines_in_patch": denom,
            "f2p_covered": len(f2p_hit),
            "p2p_covered": len(p2p_hit),
            "union_covered": len(union_hit),
            "f2p_pct": pct(len(f2p_hit), denom),
            "p2p_pct": pct(len(p2p_hit), denom),
            "union_pct": pct(len(union_hit), denom),
        }
        total_added += len(lines)
        total_executable += denom
        total_f2p += len(f2p_hit)
        total_p2p += len(p2p_hit)
        total_union += len(union_hit)

    summary = {
        "lines_in_patch_total": total_added,
        "executable_lines_in_patch": total_executable,
        "f2p_covered": total_f2p,
        "p2p_covered": total_p2p,
        "union_covered": total_union,
        "f2p_pct": pct(total_f2p, total_executable) or 0.0,
        "p2p_pct": pct(total_p2p, total_executable) or 0.0,
        "union_pct": pct(total_union, total_executable) or 0.0,
        "coverage_complete": coverage_complete,
    }
    report = {
        "instance_id": "Apache-Flink_FLIP-467-Introduce-Generalized-Watermarks_PR-25731",
        "files": files_report,
        "summary": summary,
        "tool_status": tool_status,
        "coverage_complete": coverage_complete,
    }
    Path(args.out).write_text(json.dumps(report, indent=2))
    print(json.dumps(summary, indent=2))
    return 0 if coverage_complete else 2


if __name__ == "__main__":
    sys.exit(main())

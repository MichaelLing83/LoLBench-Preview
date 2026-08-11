#!/usr/bin/env python3
"""Compute F2P and P2P line coverage of solution.patch (Java/JaCoCo flavor).

For each source file modified by solution.patch we:
  1. Parse the patch to extract the set of post-image line numbers
     added (i.e. lines that exist on disk after solution.patch is
     applied — those are the ones the tests can potentially execute).
  2. Parse the JaCoCo XML report and extract per-source-file line
     coverage (a line is "covered" if the report's <line .../> element
     has ci > 0).
  3. Intersect lines-added-by-patch with lines-executed-by-tests.

Output:
  /out/coverage_report.json with:
    files:    per-file detail (lines_in_patch, executable_lines_in_patch,
              f2p_covered, p2p_covered, union_covered, *_pct)
    summary:  totals + percentages for F2P, P2P, and F2P∪P2P
    tool_status: per-XML success/error
"""
import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict


def parse_patched_lines(patch_path):
    """Return {repo_path: set(post-image line numbers added or modified)}."""
    out = defaultdict(set)
    cur = None
    new_line = None
    for raw in open(patch_path):
        line = raw.rstrip('\n')
        m = re.match(r'^diff --git a/(.*) b/(.*)$', line)
        if m:
            cur = m.group(2)
            new_line = None
            continue
        if cur is None:
            continue
        m = re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@', line)
        if m:
            new_line = int(m.group(1))
            continue
        if new_line is None:
            continue
        if line.startswith('+++'):
            continue
        if line.startswith('+'):
            out[cur].add(new_line)
            new_line += 1
        elif line.startswith('-'):
            # deletion — does not advance post-image line counter
            pass
        elif line.startswith(' ') or line == '':
            new_line += 1
        elif line.startswith('\\'):
            # "\ No newline at end of file"
            pass
    return dict(out)


def classify(path):
    if path.endswith('.java'):
        return 'java'
    return 'other'


def load_jacoco_xml(xml_path, flink_root):
    """Return ({repo_path: (executed:set[int], executable:set[int])}, status).

    JaCoCo XML structure:
      <report>
        <package name="org/apache/flink/configuration">
          <sourcefile name="ConfigOption.java">
            <line nr="123" mi="0" ci="3" mb="0" cb="2"/>
            ...
    Where ci > 0 ⇒ at least one instruction in the line was hit.
    """
    if not os.path.exists(xml_path) or os.path.getsize(xml_path) == 0:
        return {}, {"ok": False, "error": f"no/empty XML at {xml_path}"}
    try:
        root = ET.parse(xml_path).getroot()
    except ET.ParseError as e:
        return {}, {"ok": False, "error": f"XML parse: {e}"}

    out = {}
    for pkg in root.findall('package'):
        pkg_name = pkg.attrib.get('name', '').replace('.', '/')
        for sf in pkg.findall('sourcefile'):
            sf_name = sf.attrib.get('name', '')
            if not sf_name:
                continue
            # Reconstruct repo-relative path.  JaCoCo's --sourcefiles
            # arg pointed at flink-core/src/main/java, so the repo path is:
            #   flink-core/src/main/java/<pkg>/<sourcefile>
            rel = os.path.join('flink-core', 'src', 'main', 'java', pkg_name, sf_name)
            executable = set()
            executed = set()
            for ln in sf.findall('line'):
                nr = int(ln.attrib.get('nr', 0))
                mi = int(ln.attrib.get('mi', 0))   # missed instructions
                ci = int(ln.attrib.get('ci', 0))   # covered instructions
                if (mi + ci) == 0:
                    continue   # not an executable line
                executable.add(nr)
                if ci > 0:
                    executed.add(nr)
            out[rel] = (executed, executable)
    return out, {"ok": True, "error": None}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--solution-patch', required=True)
    ap.add_argument('--flink-root',     required=True)
    ap.add_argument('--f2p-xml',        required=True)
    ap.add_argument('--p2p-xml',        required=True)
    ap.add_argument('--out',            required=True)
    args = ap.parse_args()

    patched = parse_patched_lines(args.solution_patch)
    print(f"solution.patch touches {len(patched)} file(s)")
    for p, lines in patched.items():
        print(f"  {p:80s}  {len(lines):4d} post-image lines  [{classify(p)}]")

    f2p_map, f2p_status = load_jacoco_xml(args.f2p_xml, args.flink_root)
    p2p_map, p2p_status = load_jacoco_xml(args.p2p_xml, args.flink_root)
    tool_status = {"f2p_jacoco": f2p_status, "p2p_jacoco": p2p_status}
    coverage_complete = all(s.get("ok") for s in tool_status.values())

    files_report = {}
    total_added = 0
    total_executable = 0
    total_f2p = 0
    total_p2p = 0
    total_union = 0
    for rel, lines in patched.items():
        kind = classify(rel)
        if kind != 'java':
            files_report[rel] = {
                "kind": kind,
                "lines_in_patch": len(lines),
                "note": "skipped: not a measurable source file",
            }
            continue
        f2p_exec, f2p_able = f2p_map.get(rel, (set(), set()))
        p2p_exec, p2p_able = p2p_map.get(rel, (set(), set()))
        executable_in_file = f2p_able | p2p_able
        executable_added = lines & executable_in_file
        f2p_hit = executable_added & f2p_exec
        p2p_hit = executable_added & p2p_exec
        union   = f2p_hit | p2p_hit
        denom = len(executable_added)
        files_report[rel] = {
            "kind": kind,
            "lines_in_patch":            len(lines),
            "executable_lines_in_patch": denom,
            "f2p_covered":   len(f2p_hit),
            "p2p_covered":   len(p2p_hit),
            "union_covered": len(union),
            "f2p_pct":   round(100 * len(f2p_hit) / denom, 1) if denom else None,
            "p2p_pct":   round(100 * len(p2p_hit) / denom, 1) if denom else None,
            "union_pct": round(100 * len(union)   / denom, 1) if denom else None,
        }
        total_added      += len(lines)
        total_executable += denom
        total_f2p   += len(f2p_hit)
        total_p2p   += len(p2p_hit)
        total_union += len(union)

    summary = {
        "lines_in_patch_total":      total_added,
        "executable_lines_in_patch": total_executable,
        "f2p_covered":   total_f2p,
        "p2p_covered":   total_p2p,
        "union_covered": total_union,
        "f2p_pct":   round(100 * total_f2p   / total_executable, 1) if total_executable else 0.0,
        "p2p_pct":   round(100 * total_p2p   / total_executable, 1) if total_executable else 0.0,
        "union_pct": round(100 * total_union / total_executable, 1) if total_executable else 0.0,
        "coverage_complete": coverage_complete,
    }
    report = {
        "instance_id":       "Apache-Flink_FLIP-77-Introduce-ConfigOptions-with-Data-Types_PR-9976",
        "files":             files_report,
        "summary":           summary,
        "tool_status":       tool_status,
        "coverage_complete": coverage_complete,
    }
    json.dump(report, open(args.out, 'w'), indent=2)
    print(json.dumps(summary, indent=2))
    if not coverage_complete:
        failures = [name for name, s in tool_status.items() if not s.get("ok")]
        print(f"\nWARN: coverage_report is INCOMPLETE — failing tools: {', '.join(failures)}",
              file=sys.stderr)
        sys.exit(2)
    sys.exit(0)


if __name__ == '__main__':
    main()

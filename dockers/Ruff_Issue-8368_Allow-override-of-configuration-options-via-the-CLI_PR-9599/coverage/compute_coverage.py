#!/usr/bin/env python3
"""Compute F2P and P2P line coverage of solution.patch for a Rust project
via LCOV reports produced by cargo-llvm-cov.

Algorithm:
  1. Parse solution.patch's post-image added line numbers per source file.
  2. Parse the F2P and P2P LCOV reports (DA: line numbers per file).
  3. Intersect: per source file, count
       - executable lines added (LCOV-tagged + in patch)
       - F2P-covered lines (LCOV executed count > 0 + in patch)
       - P2P-covered lines
  4. Emit /out/coverage_report.json.
"""
import argparse, json, os, re, sys
from collections import defaultdict


def parse_patched_lines(patch_path):
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
            pass
        elif line.startswith(' ') or line == '':
            new_line += 1
        elif line.startswith('\\'):
            pass
    return dict(out)


def parse_lcov(path):
    """Return {file_rel_to_workspace: (executed_lines:set, executable_lines:set)}."""
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}, {"ok": False, "error": f"no/empty LCOV at {path}"}
    out = {}
    cur_file = None
    executed = set()
    executable = set()
    with open(path) as fh:
        for raw in fh:
            line = raw.rstrip('\n')
            if line.startswith('SF:'):
                cur_file = line[3:]
                executed = set()
                executable = set()
            elif line.startswith('DA:'):
                # DA:<line>,<hit_count>
                m = re.match(r'DA:(\d+),(\d+)', line)
                if m:
                    ln, ct = int(m.group(1)), int(m.group(2))
                    executable.add(ln)
                    if ct > 0:
                        executed.add(ln)
            elif line == 'end_of_record':
                if cur_file:
                    out[cur_file] = (executed, executable)
                cur_file = None
    return out, {"ok": True, "error": None}


def normalize_path(abs_path, ruff_root):
    """Convert /workspace/ruff/crates/ruff/src/foo.rs → crates/ruff/src/foo.rs."""
    if abs_path.startswith(ruff_root):
        return abs_path[len(ruff_root):].lstrip('/')
    return abs_path


def classify(path):
    if path.endswith('.rs'):
        return 'rust'
    if path.endswith('.toml') or path.endswith('.lock'):
        return 'build'
    if path.endswith('.md') or path.endswith('.html'):
        return 'doc'
    return 'other'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--solution-patch', required=True)
    ap.add_argument('--ruff-root',      required=True)
    ap.add_argument('--f2p-lcov',       required=True)
    ap.add_argument('--p2p-lcov',       required=True)
    ap.add_argument('--out',            required=True)
    args = ap.parse_args()

    patched = parse_patched_lines(args.solution_patch)
    print(f"solution.patch touches {len(patched)} file(s)")
    for p, lines in patched.items():
        print(f"  {p:70s}  {len(lines):4d} post-image lines  [{classify(p)}]")

    f2p_raw, f2p_status = parse_lcov(args.f2p_lcov)
    p2p_raw, p2p_status = parse_lcov(args.p2p_lcov)
    tool_status = {"f2p_lcov": f2p_status, "p2p_lcov": p2p_status}
    coverage_complete = all(s.get("ok") for s in tool_status.values())

    # Re-key LCOV file paths to repo-relative
    f2p_map = {normalize_path(p, args.ruff_root): v for p, v in f2p_raw.items()}
    p2p_map = {normalize_path(p, args.ruff_root): v for p, v in p2p_raw.items()}

    files_report = {}
    total_added = 0
    total_executable = 0
    total_f2p = 0
    total_p2p = 0
    total_union = 0
    for rel, lines in patched.items():
        kind = classify(rel)
        if kind != 'rust':
            files_report[rel] = {"kind": kind, "lines_in_patch": len(lines),
                                 "note": "skipped: not a measurable .rs file"}
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
        "instance_id":       "Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599",
        "files":             files_report,
        "summary":           summary,
        "tool_status":       tool_status,
        "coverage_complete": coverage_complete,
    }
    json.dump(report, open(args.out, 'w'), indent=2)
    print(json.dumps(summary, indent=2))
    if not coverage_complete:
        failures = [n for n, s in tool_status.items() if not s.get("ok")]
        print(f"\nWARN: coverage_report is INCOMPLETE — failing tools: {', '.join(failures)}", file=sys.stderr)
        sys.exit(2)
    sys.exit(0)


if __name__ == '__main__':
    main()

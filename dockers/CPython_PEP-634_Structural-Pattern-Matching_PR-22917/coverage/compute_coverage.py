#!/usr/bin/env python3
"""Compute F2P and P2P line coverage of solution.patch for CPython (gcov-only).

For each C source file modified by solution.patch we:
  1. Parse the patch to extract the set of post-image line numbers added
     or modified (i.e. lines that exist on disk after solution.patch is
     applied — the lines the tests can potentially execute).
  2. Render C coverage by running `gcovr` against the .gcda snapshots
     tar'd by run_coverage.sh, scoped to the patched .c/.h files
     (gcovr's --filter takes a regex of source paths).
  3. Intersect lines-added-by-patch with lines-executed-by-tests.
  4. Cross-check the F2P/P2P unittest results.json that run_coverage.sh
     captured for each selection — if any selected test was not PASSED,
     coverage_complete is forced to false (the numbers below may be
     misleading because they were collected during a failing run).

scope. The summary numbers (lines_in_patch_total, f2p_covered, …) cover
**only the hand-written gcov-measurable subset of solution.patch** — .c
and .h files outside machine-generated parser / AST / clinic outputs.
solution.patch also
touches Python stdlib source (Lib/ast.py, Lib/dataclasses.py,
Lib/keyword.py, Lib/opcode.py, Lib/collections/__init__.py,
Lib/importlib/_bootstrap_external.py, Lib/test/libregrtest/pgo.py),
the grammar definition (Grammar/python.gram, Parser/Python.asdl), and
the asdl_c.py generator script.  Those lines are recorded under
`files[…].kind` ∈ {python, grammar, build, generated, other} with
`note: skipped` and contribute their raw-line count to
`lines_in_patch_total_all` but are NOT included in the executable-lines
denominator or the percentage metrics.  Adding Python-side coverage for
the stdlib changes would
require a separate `coverage.py` run; documented as future work.

Generated argument-clinic headers under Python/clinic/*.c.h get their
coverage attributed via the .c that #includes them (typically the
file's own gcov entry), so the report sometimes shows 0 executable
lines in those headers even when they're fully exercised — that's a
limitation of source-line coverage on machine-generated #include
fragments, not of this analyser.

Output:
  /out/coverage_report.json with:
    files:    per-file detail (kind, total_lines, f2p_covered, p2p_covered)
    summary:  totals + percentages for F2P, P2P, and F2P∪P2P (C-only)
    tool_status:  per-tool ok/err for diagnosability
    coverage_complete: true iff every C tool succeeded AND every selected
                       F2P/P2P unittest was PASSED in the coverage run
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
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
    """File-kind for coverage attribution.

    'c'         — .c / .h (gcov-instrumented; counted in C coverage denominator)
    'generated' — generated parser / AST C outputs and generated headers
                  (e.g. Parser/parser.c, Python/Python-ast.c,
                  Python/clinic/*.c.h, Include/internal/*_generated.h).
    'python'    — .py files in this PR (Tools/peg_generator/*.py); not
                  covered by gcov — recorded but excluded from the
                  executable-lines denominator.
    'grammar'   — .gram / .gitignore / .clang-format etc. in
                  Tools/peg_generator/; data, not executable C.
    'build'     — Makefile.pre.in, configure(.ac), pyconfig.h.in,
                  Modules/Setup, PC/config.c (config table), PCbuild/*.
    'other'     — anything else (e.g. .pip requirements file).
    """
    if path in ('Parser/parser.c', 'Python/Python-ast.c'):
        return 'generated'
    if path.endswith(('.c', '.h')):
        if 'clinic/' in path or path.endswith('_generated.h'):
            return 'generated'
        return 'c'
    if path.endswith('.py'):
        return 'python'
    if path.endswith(('.gram', '.gitignore', '.clang-format', '.pip',
                       '.toml', '.ini')):
        return 'grammar'
    if path in ('configure', 'configure.ac', 'pyconfig.h.in',
                 'Makefile.pre.in', 'Modules/Setup', 'PC/config.c'):
        return 'build'
    if path.startswith('PCbuild/'):
        return 'build'
    return 'other'


def load_test_results(cov_dir):
    """Load run_coverage.sh's per-test verdict JSON.

    Returns (all_passed: bool, summary_str).  Missing file → (False, …)
    so that an absent run is treated the same as a failed run.
    """
    path = os.path.join(cov_dir, 'results.json')
    if not os.path.exists(path):
        return False, f"no results.json at {path}"
    try:
        data = json.load(open(path))
    except Exception as e:
        return False, f"results.json parse error: {e}"
    counts = {"PASSED": 0, "FAILED": 0, "ERROR": 0, "SKIPPED": 0}
    failed_ids = []
    for tid, info in data.items():
        verdict = info.get("verdict", "ERROR")
        counts[verdict] = counts.get(verdict, 0) + 1
        if verdict != "PASSED":
            failed_ids.append(f"{tid}:{verdict}")
    all_passed = (counts["FAILED"] == 0 and counts["ERROR"] == 0
                  and counts["SKIPPED"] == 0 and counts["PASSED"] > 0)
    return all_passed, (
        f"{counts['PASSED']}P/{counts['FAILED']}F/"
        f"{counts['ERROR']}E/{counts['SKIPPED']}S"
        + (f"  failures: {failed_ids[:3]}…" if failed_ids else "")
    )


def load_cpp_coverage(gcda_tarball, cpython_root, patched_files):
    """Return (per_file, status_dict).

    per_file: {repo_path: (set_of_executed_lines, set_of_executable_lines)}
    status:   {"ok": bool, "error": str|None}
    """
    if not os.path.exists(gcda_tarball):
        return {}, {"ok": False, "error": f"no gcda tarball at {gcda_tarball}"}

    # The .gcda files were tar'd relative to /workspace/cpython.  Extract
    # them back into the source tree (gcov resolves source paths from
    # the .gcno file's recorded original path, which points at the
    # build-dir-rooted source).
    tmp = tempfile.mkdtemp(prefix='cov_c_')
    try:
        try:
            with tarfile.open(gcda_tarball, 'r:gz') as tf:
                tf.extractall(cpython_root)
        except Exception as e:
            return {}, {"ok": False, "error": f"gcda extract failed: {e}"}

        out_json = os.path.join(tmp, 'gcovr.json')
        # Build a gcovr --filter regex that scopes to the patched files
        # (otherwise gcovr walks the entire CPython tree, ~minutes).
        # gcovr regexes match the relative path under --root.
        patched_c_h = [p for p in patched_files
                       if p.endswith(('.c', '.h')) and 'clinic/' not in p]
        if not patched_c_h:
            return {}, {"ok": True, "error": None, "note": "no .c/.h files in patch"}
        filter_re = '|'.join(re.escape(p) for p in patched_c_h)

        cmd = [
            'gcovr',
            '--root', cpython_root,
            '--gcov-executable', 'gcov',
            '--filter', filter_re,
            '--json',
            '--output', out_json,
            cpython_root,
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, timeout=600)
        except subprocess.CalledProcessError as e:
            err = (e.stderr or b'').decode(errors='replace')[:600]
            print(f"WARN: gcovr failed (rc={e.returncode}): {err}",
                  file=sys.stderr)
            return {}, {"ok": False, "error": f"gcovr rc={e.returncode}: {err}"}
        except subprocess.TimeoutExpired:
            return {}, {"ok": False, "error": "gcovr timeout"}

        out = {}
        try:
            data = json.load(open(out_json))
        except Exception as e:
            return {}, {"ok": False, "error": f"gcovr json load: {e}"}
        for f in data.get('files', []):
            rel = f.get('file')
            if rel is None:
                continue
            executable = set()
            executed = set()
            for ln in f.get('lines', []):
                if ln.get('gcovr/noncode'):
                    continue
                num = ln['line_number']
                executable.add(num)
                if ln.get('count', 0) > 0:
                    executed.add(num)
            out[rel] = (executed, executable)
        return out, {"ok": True, "error": None}
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--solution-patch', required=True)
    ap.add_argument('--cpython-root',   required=True)
    ap.add_argument('--f2p-cov',        required=True)
    ap.add_argument('--p2p-cov',        required=True)
    ap.add_argument('--out',            required=True)
    args = ap.parse_args()

    patched = parse_patched_lines(args.solution_patch)
    print(f"solution.patch touches {len(patched)} file(s):")
    for p, lines in sorted(patched.items()):
        print(f"  {p:60s}  {len(lines):4d} post-image lines  [{classify(p)}]")

    patched_paths = list(patched.keys())
    f2p_cpp, f2p_cpp_status = load_cpp_coverage(
        os.path.join(args.f2p_cov, 'gcda.tar.gz'),
        args.cpython_root, patched_paths)
    p2p_cpp, p2p_cpp_status = load_cpp_coverage(
        os.path.join(args.p2p_cov, 'gcda.tar.gz'),
        args.cpython_root, patched_paths)

    f2p_run_ok, f2p_run_summary = load_test_results(args.f2p_cov)
    p2p_run_ok, p2p_run_summary = load_test_results(args.p2p_cov)

    tool_status = {
        "f2p_cpp": f2p_cpp_status,
        "p2p_cpp": p2p_cpp_status,
        "f2p_run": {
            "ok": f2p_run_ok, "summary": f2p_run_summary,
            "error": None if f2p_run_ok else f"F2P run not fully PASSED: {f2p_run_summary}",
        },
        "p2p_run": {
            "ok": p2p_run_ok, "summary": p2p_run_summary,
            "error": None if p2p_run_ok else f"P2P run not fully PASSED: {p2p_run_summary}",
        },
    }
    coverage_complete = all(s.get("ok") for s in tool_status.values())

    def bundle_for(rel, kind):
        if kind in ('c', 'generated'):
            return (f2p_cpp.get(rel, (set(), set())),
                    p2p_cpp.get(rel, (set(), set())))
        return ((set(), set()), (set(), set()))

    NON_C_KINDS = {'build', 'other', 'python', 'grammar', 'generated'}
    files_report = {}
    total_added_c = 0           # raw added lines, gcov-measurable subset only
    total_added_all = 0         # raw added lines across all kinds
    total_executable = 0
    total_f2p = 0
    total_p2p = 0
    total_union = 0
    for rel, lines in patched.items():
        kind = classify(rel)
        total_added_all += len(lines)
        if kind in NON_C_KINDS:
            files_report[rel] = {
                "kind": kind,
                "lines_in_patch": len(lines),
                "note": ("skipped: not gcov-measurable "
                          "(see compute_coverage.py module docstring)"),
            }
            continue
        (f2p_exec, f2p_able), (p2p_exec, p2p_able) = bundle_for(rel, kind)
        executable_in_file = f2p_able | p2p_able
        executable_added = lines & executable_in_file
        f2p_hit = executable_added & f2p_exec
        p2p_hit = executable_added & p2p_exec
        union = f2p_hit | p2p_hit
        denom = len(executable_added)
        files_report[rel] = {
            "kind": kind,
            "lines_in_patch": len(lines),
            "executable_lines_in_patch": denom,
            "f2p_covered":   len(f2p_hit),
            "p2p_covered":   len(p2p_hit),
            "union_covered": len(union),
            "f2p_pct":   round(100 * len(f2p_hit) / denom, 1) if denom else None,
            "p2p_pct":   round(100 * len(p2p_hit) / denom, 1) if denom else None,
            "union_pct": round(100 * len(union)   / denom, 1) if denom else None,
        }
        total_added_c    += len(lines)
        total_executable += denom
        total_f2p   += len(f2p_hit)
        total_p2p   += len(p2p_hit)
        total_union += len(union)
    # alias name kept for backward compatibility with sidecar tooling
    total_added = total_added_c

    summary = {
        "scope": "gcov-only hand-written C / .h; generated parser/AST outputs, Python, grammar, and build files are recorded but not measured",
        "lines_in_patch_total":      total_added,        # C subset (kept name for backward compat with sidecar tools)
        "lines_in_patch_total_all":  total_added_all,    # NEW: every file kind, raw line count
        "lines_in_patch_c_only":     total_added_c,      # NEW: explicit C-only mirror of lines_in_patch_total
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
        "suite":            os.environ.get("LOLBENCH_SUITE", "orig"),
        "files":             files_report,
        "summary":           summary,
        "tool_status":       tool_status,
        "coverage_complete": coverage_complete,
    }
    json.dump(report, open(args.out, 'w'), indent=2)
    print(json.dumps(summary, indent=2))
    if not coverage_complete:
        failures = [name for name, s in tool_status.items() if not s.get("ok")]
        print(f"\nWARN: coverage_report INCOMPLETE — failing: {', '.join(failures)}",
              file=sys.stderr)
        sys.exit(2)
    sys.exit(0)


if __name__ == '__main__':
    main()

"""Compute the coverage_report.json from coverage.py outputs for PEP-680.

Reads:
  - solution.patch  (to enumerate which file:line pairs are in scope)
  - coverage.py JSON for the F2P lane
  - coverage.py JSON for the P2P lane
  - per-test verdict files (id PASSED|FAILED|ERROR|SKIPPED per line)

Writes:
  - /out/coverage_report.json

Schema:
  {
    "scope": "coverage.py — Python files in solution.patch (Lib/tomllib/*.py)",
    "files_in_scope": [...],
    "lines_in_patch_total": N,        # all lines in solution.patch (added)
    "lines_in_patch_total_all": N,
    "lines_in_patch_python": N,
    "executable_lines_in_patch": N,   # coverage.py "executable lines" count
    "f2p_covered": N,
    "p2p_covered": N,
    "union_covered": N,
    "f2p_pct": ...,
    "p2p_pct": ...,
    "union_pct": ...,
    "coverage_complete": bool,
    "tool_status": {
        "f2p_run": {"ok": bool, "summary": "13P/0F/0E/0S", "error": null},
        "p2p_run": {"ok": bool, "summary": "37P/0F/0E/0S", "error": null},
        "f2p_json": {"ok": bool, "error": null},
        "p2p_json": {"ok": bool, "error": null},
    },
    ...
  }
"""
import argparse
import json
import os
import pathlib
import re
import sys


def parse_solution_patch(path, *, all_files=False):
    """Return {filename: set(line_numbers_added)} from a unified-diff patch.

    If all_files is False (default), keep only Python source under
    Lib/tomllib/ (the coverage scope).  If all_files is True, count
    every added line across every file in the patch — used to report
    the total addition count for spec/README cross-checking, separate
    from the Python-only coverage denominator.
    """
    text = pathlib.Path(path).read_text()
    files = {}
    current_file = None
    in_new_hunk = False
    new_lineno = 0
    line_iter = iter(text.splitlines(True))
    for line in line_iter:
        m = re.match(r"^\+\+\+ b/(.+)$", line)
        if m:
            current_file = m.group(1).rstrip("\r\n")
            if all_files:
                files.setdefault(current_file, set())
            elif current_file.startswith("Lib/tomllib/") and current_file.endswith(".py"):
                files.setdefault(current_file, set())
            else:
                current_file = None
            in_new_hunk = False
            continue
        m = re.match(r"^@@ .* \+(\d+)(?:,\d+)? @@", line)
        if m and current_file:
            new_lineno = int(m.group(1))
            in_new_hunk = True
            continue
        if not in_new_hunk or not current_file:
            continue
        if line.startswith("+") and not line.startswith("+++"):
            files[current_file].add(new_lineno)
            new_lineno += 1
        elif line.startswith("-") and not line.startswith("---"):
            pass
        elif line.startswith(" "):
            new_lineno += 1
        else:
            in_new_hunk = False
    return files


def parse_coverage_json(path):
    """Return {filename: {"executed": set, "missing": set}} from coverage.py json."""
    if not os.path.isfile(path):
        return {}
    raw = json.load(open(path))
    out = {}
    for fname, info in raw.get("files", {}).items():
        out[fname] = {
            "executed": set(info.get("executed_lines", [])),
            "missing": set(info.get("missing_lines", [])),
        }
    return out


def parse_verdicts(path):
    """Return dict {test_id: verdict} from "id verdict" file."""
    out = {}
    if not os.path.isfile(path):
        return out
    for line in pathlib.Path(path).read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.rsplit(None, 1)
        if len(parts) != 2:
            continue
        out[parts[0]] = parts[1]
    return out


def verdict_summary(verdicts):
    """Return e.g. '13P/0F/0E/0S'."""
    p = sum(1 for v in verdicts.values() if v == "PASSED")
    f = sum(1 for v in verdicts.values() if v == "FAILED")
    e = sum(1 for v in verdicts.values() if v == "ERROR")
    s = sum(1 for v in verdicts.values() if v == "SKIPPED")
    return f"{p}P/{f}F/{e}E/{s}S"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-patch", required=True)
    ap.add_argument("--f2p-json", required=True)
    ap.add_argument("--p2p-json", required=True)
    ap.add_argument("--f2p-verdicts", required=True)
    ap.add_argument("--p2p-verdicts", required=True)
    ap.add_argument("--f2p-json-ok", required=True)
    ap.add_argument("--p2p-json-ok", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    patch_lines = parse_solution_patch(args.solution_patch)
    patch_lines_all = parse_solution_patch(args.solution_patch, all_files=True)
    f2p_cov = parse_coverage_json(args.f2p_json)
    p2p_cov = parse_coverage_json(args.p2p_json)
    f2p_verdicts = parse_verdicts(args.f2p_verdicts)
    p2p_verdicts = parse_verdicts(args.p2p_verdicts)

    f2p_run_ok = bool(f2p_verdicts) and all(v == "PASSED" for v in f2p_verdicts.values())
    p2p_run_ok = bool(p2p_verdicts) and all(v == "PASSED" for v in p2p_verdicts.values())
    f2p_json_ok = args.f2p_json_ok.lower() == "true"
    p2p_json_ok = args.p2p_json_ok.lower() == "true"

    # Coverage.py reports filenames as absolute paths inside the container
    # (e.g. /workspace/cpython/Lib/tomllib/_parser.py).  Map them back to
    # the relative path so we can join with solution.patch entries.
    def normalize_keys(d):
        return {
            f.replace("/workspace/cpython/", "").lstrip("/"): info
            for f, info in d.items()
        }

    f2p_cov_n = normalize_keys(f2p_cov)
    p2p_cov_n = normalize_keys(p2p_cov)

    files_in_scope = sorted(patch_lines.keys())
    rows = []
    f2p_total_cov = 0
    p2p_total_cov = 0
    union_total_cov = 0
    exec_total = 0
    for fname in files_in_scope:
        patch_set = patch_lines[fname]
        f2p_exec = f2p_cov_n.get(fname, {}).get("executed", set())
        p2p_exec = p2p_cov_n.get(fname, {}).get("executed", set())
        executable = f2p_cov_n.get(fname, {}).get("executed", set()) | f2p_cov_n.get(fname, {}).get("missing", set()) \
                     | p2p_cov_n.get(fname, {}).get("executed", set()) | p2p_cov_n.get(fname, {}).get("missing", set())
        executable_in_patch = patch_set & executable
        f2p_in_patch = patch_set & f2p_exec
        p2p_in_patch = patch_set & p2p_exec
        union_in_patch = f2p_in_patch | p2p_in_patch
        rows.append({
            "file": fname,
            "lines_in_patch": len(patch_set),
            "executable_lines_in_patch": len(executable_in_patch),
            "f2p_covered": len(f2p_in_patch),
            "p2p_covered": len(p2p_in_patch),
            "union_covered": len(union_in_patch),
        })
        f2p_total_cov += len(f2p_in_patch)
        p2p_total_cov += len(p2p_in_patch)
        union_total_cov += len(union_in_patch)
        exec_total += len(executable_in_patch)

    total_patch_python = sum(len(v) for v in patch_lines.values())
    total_patch_all = sum(len(v) for v in patch_lines_all.values())

    def pct(n, d):
        return round(100.0 * n / d, 1) if d else 0.0

    summary = {
        "scope": "coverage.py — Python files in solution.patch (Lib/tomllib/*.py). Python/stdlib_module_names.h (+1 line) is not Python-executable and is excluded.",
        "lines_in_patch_total": total_patch_python,
        "lines_in_patch_total_all": total_patch_all,
        "lines_in_patch_python": total_patch_python,
        "executable_lines_in_patch": exec_total,
        "f2p_covered": f2p_total_cov,
        "p2p_covered": p2p_total_cov,
        "union_covered": union_total_cov,
        "f2p_pct": pct(f2p_total_cov, exec_total),
        "p2p_pct": pct(p2p_total_cov, exec_total),
        "union_pct": pct(union_total_cov, exec_total),
        "coverage_complete": all([f2p_run_ok, p2p_run_ok, f2p_json_ok, p2p_json_ok]),
    }

    report = {
        "instance_id": "CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498",
        "files_in_scope": files_in_scope,
        "per_file": rows,
        "summary": summary,
        "tool_status": {
            "f2p_run": {
                "ok": f2p_run_ok,
                "summary": verdict_summary(f2p_verdicts),
                "error": None if f2p_run_ok else "non-PASSED verdict(s) in F2P",
            },
            "p2p_run": {
                "ok": p2p_run_ok,
                "summary": verdict_summary(p2p_verdicts),
                "error": None if p2p_run_ok else "non-PASSED verdict(s) in P2P",
            },
            "f2p_json": {"ok": f2p_json_ok, "error": None if f2p_json_ok else "coverage.json emit failed"},
            "p2p_json": {"ok": p2p_json_ok, "error": None if p2p_json_ok else "coverage.json emit failed"},
        },
        "coverage_complete": summary["coverage_complete"],
    }

    pathlib.Path(args.out).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["summary"], indent=2))


if __name__ == "__main__":
    main()

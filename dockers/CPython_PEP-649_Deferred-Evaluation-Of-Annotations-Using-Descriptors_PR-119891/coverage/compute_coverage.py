"""Compute the coverage_report.json from hybrid Py + C tools for PEP-649.

Reads:
  - solution.patch  (to enumerate which file:line pairs are in scope)
  - coverage.py JSON for the F2P + P2P lanes (Lib/typing.py + Lib/ast.py)
  - gcovr JSON     for the F2P + P2P lanes (13 C/header files)
  - per-test verdict files

Writes:
  - /out/coverage_report.json
"""
import argparse
import json
import os
import pathlib
import re


PYTHON_SCOPE_FILES = {
    "Lib/annotationlib.py",
    "Lib/dataclasses.py",
    "Lib/functools.py",
    "Lib/inspect.py",
    "Lib/typing.py",
}
C_SCOPE_FILES = set()  # PEP-649 PR-119891 has no C source — only Python files + stdlib_module_names.h regenerated
# Note: Grammar/python.gram and Parser/Python.asdl are non-executable
# grammar/schema sources. They contribute to coverage indirectly via the
# generated parser.c and Python-ast.c, which are in C_SCOPE_FILES.


def parse_solution_patch(path, *, scope):
    """Parse added line numbers from a unified-diff patch.

    scope: "python" (only PEP-649 Python files), "c" (only PEP-649 C files),
           "all" (every file).
    """
    text = pathlib.Path(path).read_text()
    files = {}
    current_file = None
    in_new_hunk = False
    new_lineno = 0
    for line in text.splitlines(True):
        m = re.match(r"^\+\+\+ b/(.+)$", line)
        if m:
            current_file = m.group(1).rstrip("\r\n")
            keep = False
            if scope == "all":
                keep = True
            elif scope == "python":
                keep = current_file in PYTHON_SCOPE_FILES
            elif scope == "c":
                keep = current_file in C_SCOPE_FILES
            if keep:
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


def parse_coverage_py_json(path):
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


def parse_gcovr_json(path):
    if not os.path.isfile(path):
        return {}
    raw = json.load(open(path))
    out = {}
    for f in raw.get("files", []):
        fname = f.get("file")
        if not fname:
            continue
        executed = set()
        missing = set()
        for ln in f.get("lines", []):
            lineno = ln.get("line_number")
            if lineno is None:
                continue
            if ln.get("count", 0) > 0:
                executed.add(lineno)
            else:
                missing.add(lineno)
        out[fname] = {"executed": executed, "missing": missing}
    return out


def parse_verdicts(path):
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
    p = sum(1 for v in verdicts.values() if v == "PASSED")
    f = sum(1 for v in verdicts.values() if v == "FAILED")
    e = sum(1 for v in verdicts.values() if v == "ERROR")
    s = sum(1 for v in verdicts.values() if v == "SKIPPED")
    return f"{p}P/{f}F/{e}E/{s}S"


def normalize_keys(d, *, strip_prefix="/workspace/cpython/"):
    out = {}
    for f, info in d.items():
        nf = f
        if nf.startswith(strip_prefix):
            nf = nf[len(strip_prefix):]
        out[nf] = info
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-patch", required=True)
    ap.add_argument("--f2p-py-json", required=True)
    ap.add_argument("--p2p-py-json", required=True)
    ap.add_argument("--f2p-c-json", required=True)
    ap.add_argument("--p2p-c-json", required=True)
    ap.add_argument("--f2p-verdicts", required=True)
    ap.add_argument("--p2p-verdicts", required=True)
    ap.add_argument("--f2p-py-ok", required=True)
    ap.add_argument("--p2p-py-ok", required=True)
    ap.add_argument("--f2p-c-ok", required=True)
    ap.add_argument("--p2p-c-ok", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    patch_python = parse_solution_patch(args.solution_patch, scope="python")
    patch_c = parse_solution_patch(args.solution_patch, scope="c")
    patch_all = parse_solution_patch(args.solution_patch, scope="all")

    f2p_py = normalize_keys(parse_coverage_py_json(args.f2p_py_json))
    p2p_py = normalize_keys(parse_coverage_py_json(args.p2p_py_json))
    f2p_c = normalize_keys(parse_gcovr_json(args.f2p_c_json))
    p2p_c = normalize_keys(parse_gcovr_json(args.p2p_c_json))

    f2p_verdicts = parse_verdicts(args.f2p_verdicts)
    p2p_verdicts = parse_verdicts(args.p2p_verdicts)
    f2p_run_ok = bool(f2p_verdicts) and all(v == "PASSED" for v in f2p_verdicts.values())
    p2p_run_ok = bool(p2p_verdicts) and all(v == "PASSED" for v in p2p_verdicts.values())
    f2p_py_ok = args.f2p_py_ok.lower() == "true"
    p2p_py_ok = args.p2p_py_ok.lower() == "true"
    f2p_c_ok = args.f2p_c_ok.lower() == "true"
    p2p_c_ok = args.p2p_c_ok.lower() == "true"

    # Build per-file coverage rows for Python files.
    rows = []
    f2p_total = p2p_total = union_total = exec_total = 0

    def merge_executable(*infos):
        s = set()
        for info in infos:
            if not info: continue
            s |= info.get("executed", set()) | info.get("missing", set())
        return s

    for fname in sorted(patch_python.keys()):
        patch_set = patch_python[fname]
        f2p_exec = f2p_py.get(fname, {}).get("executed", set())
        p2p_exec = p2p_py.get(fname, {}).get("executed", set())
        executable = merge_executable(f2p_py.get(fname), p2p_py.get(fname))
        executable_in_patch = patch_set & executable
        f2p_in_patch = patch_set & f2p_exec
        p2p_in_patch = patch_set & p2p_exec
        union_in_patch = f2p_in_patch | p2p_in_patch
        rows.append({
            "file": fname,
            "language": "python",
            "lines_in_patch": len(patch_set),
            "executable_lines_in_patch": len(executable_in_patch),
            "f2p_covered": len(f2p_in_patch),
            "p2p_covered": len(p2p_in_patch),
            "union_covered": len(union_in_patch),
            "executable_lines_in_patch_list": sorted(executable_in_patch),
            "f2p_covered_lines": sorted(f2p_in_patch),
            "p2p_covered_lines": sorted(p2p_in_patch),
            "union_covered_lines": sorted(union_in_patch),
            "union_missing_lines": sorted(executable_in_patch - union_in_patch),
        })
        f2p_total += len(f2p_in_patch)
        p2p_total += len(p2p_in_patch)
        union_total += len(union_in_patch)
        exec_total += len(executable_in_patch)

    # Build per-file row for C file.
    for fname in sorted(patch_c.keys()):
        patch_set = patch_c[fname]
        f2p_exec = f2p_c.get(fname, {}).get("executed", set())
        p2p_exec = p2p_c.get(fname, {}).get("executed", set())
        executable = merge_executable(f2p_c.get(fname), p2p_c.get(fname))
        executable_in_patch = patch_set & executable
        f2p_in_patch = patch_set & f2p_exec
        p2p_in_patch = patch_set & p2p_exec
        union_in_patch = f2p_in_patch | p2p_in_patch
        rows.append({
            "file": fname,
            "language": "c",
            "lines_in_patch": len(patch_set),
            "executable_lines_in_patch": len(executable_in_patch),
            "f2p_covered": len(f2p_in_patch),
            "p2p_covered": len(p2p_in_patch),
            "union_covered": len(union_in_patch),
            "executable_lines_in_patch_list": sorted(executable_in_patch),
            "f2p_covered_lines": sorted(f2p_in_patch),
            "p2p_covered_lines": sorted(p2p_in_patch),
            "union_covered_lines": sorted(union_in_patch),
            "union_missing_lines": sorted(executable_in_patch - union_in_patch),
        })
        f2p_total += len(f2p_in_patch)
        p2p_total += len(p2p_in_patch)
        union_total += len(union_in_patch)
        exec_total += len(executable_in_patch)

    total_patch_python = sum(len(v) for v in patch_python.values())
    total_patch_c = sum(len(v) for v in patch_c.values())
    total_patch_all = sum(len(v) for v in patch_all.values())

    def pct(n, d):
        return round(100.0 * n / d, 1) if d else 0.0

    summary = {
        "scope": (
            "coverage.py for the 5 PEP-649 Python files (Lib/typing.py, "
            "Lib/ast.py, Lib/keyword.py, Lib/opcode.py, "
            "Lib/importlib/_bootstrap_external.py) + gcov/gcovr for the "
            "34 PEP-649 C source/header files (Parser/parser.c + action_helpers.c, "
            "Python/{compile,symtable,ast,ast_opt,Python-ast,bytecodes,"
            "intrinsics,pylifecycle}.c + generated tables, "
            "Objects/{typevarobject,funcobject,typeobject,unionobject,object}.c "
            "+ clinic glue, Modules/_typingmodule.c, plus all touched "
            "pycore_*.h / cpython/funcobject.h / opcode.h headers). "
            "Grammar/python.gram and Parser/Python.asdl are grammar / schema "
            "sources (non-executable) and so are not part of the coverage "
            "denominator; they contribute to coverage indirectly via the "
            "generated parser.c / Python-ast.c."
        ),
        "lines_in_patch_total": total_patch_python + total_patch_c,
        "lines_in_patch_total_all": total_patch_all,
        "lines_in_patch_python": total_patch_python,
        "lines_in_patch_c": total_patch_c,
        "executable_lines_in_patch": exec_total,
        "f2p_covered": f2p_total,
        "p2p_covered": p2p_total,
        "union_covered": union_total,
        "f2p_pct": pct(f2p_total, exec_total),
        "p2p_pct": pct(p2p_total, exec_total),
        "union_pct": pct(union_total, exec_total),
        "coverage_complete": all([f2p_run_ok, p2p_run_ok, f2p_py_ok, p2p_py_ok, f2p_c_ok, p2p_c_ok]),
    }

    report = {
        "instance_id": "CPython_PEP-649_Deferred-Evaluation-Of-Annotations-Using-Descriptors_PR-119891",
        "files_in_scope": sorted(list(patch_python.keys()) + list(patch_c.keys())),
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
            "f2p_py_json": {"ok": f2p_py_ok, "error": None if f2p_py_ok else "coverage.py json emit failed"},
            "p2p_py_json": {"ok": p2p_py_ok, "error": None if p2p_py_ok else "coverage.py json emit failed"},
            "f2p_c_gcovr": {"ok": f2p_c_ok, "error": None if f2p_c_ok else "gcovr --json emit failed"},
            "p2p_c_gcovr": {"ok": p2p_c_ok, "error": None if p2p_c_ok else "gcovr --json emit failed"},
        },
        "coverage_complete": summary["coverage_complete"],
    }

    pathlib.Path(args.out).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["summary"], indent=2))


if __name__ == "__main__":
    main()

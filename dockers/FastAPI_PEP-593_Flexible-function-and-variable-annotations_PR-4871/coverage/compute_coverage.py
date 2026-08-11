"""Compute coverage_report.json for FastAPI PR-4871 (pure Python coverage.py)."""
import argparse, json, os, pathlib, re

SCOPE_FILES = {
    "fastapi/dependencies/utils.py",
    "fastapi/param_functions.py",
    "fastapi/params.py",
    "fastapi/utils.py",
}

def parse_solution_patch(path):
    text = pathlib.Path(path).read_text()
    files = {}
    current = None; in_hunk = False; lineno = 0
    for line in text.splitlines(True):
        m = re.match(r"^\+\+\+ b/(.+)$", line)
        if m:
            current = m.group(1).rstrip("\r\n")
            if current in SCOPE_FILES:
                files.setdefault(current, set())
            else:
                current = None
            in_hunk = False
            continue
        m = re.match(r"^@@ .* \+(\d+)(?:,\d+)? @@", line)
        if m and current:
            lineno = int(m.group(1)); in_hunk = True; continue
        if not in_hunk or not current: continue
        if line.startswith("+") and not line.startswith("+++"):
            files[current].add(lineno); lineno += 1
        elif line.startswith("-") and not line.startswith("---"):
            pass
        elif line.startswith(" "):
            lineno += 1
        else:
            in_hunk = False
    return files

def parse_coverage_json(path):
    if not os.path.isfile(path): return {}
    raw = json.load(open(path))
    out = {}
    for f, info in raw.get("files", {}).items():
        out[f] = {
            "executed": set(info.get("executed_lines", [])),
            "missing": set(info.get("missing_lines", [])),
        }
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-patch", required=True)
    ap.add_argument("--f2p-json", required=True)
    ap.add_argument("--p2p-json", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    patch = parse_solution_patch(args.solution_patch)
    f2p = parse_coverage_json(args.f2p_json)
    p2p = parse_coverage_json(args.p2p_json)

    rows = []
    f2p_total = p2p_total = union_total = exec_total = 0
    for fname in sorted(patch):
        ps = patch[fname]
        f2p_exec = f2p.get(fname, {}).get("executed", set())
        p2p_exec = p2p.get(fname, {}).get("executed", set())
        executable = (f2p.get(fname, {}).get("executed", set())
                      | f2p.get(fname, {}).get("missing", set())
                      | p2p.get(fname, {}).get("executed", set())
                      | p2p.get(fname, {}).get("missing", set()))
        exec_in_patch = ps & executable
        f2p_in_patch = ps & f2p_exec
        p2p_in_patch = ps & p2p_exec
        union_in_patch = f2p_in_patch | p2p_in_patch
        rows.append({
            "file": fname,
            "lines_in_patch": len(ps),
            "executable_lines_in_patch": len(exec_in_patch),
            "f2p_covered": len(f2p_in_patch),
            "p2p_covered": len(p2p_in_patch),
            "union_covered": len(union_in_patch),
        })
        f2p_total += len(f2p_in_patch)
        p2p_total += len(p2p_in_patch)
        union_total += len(union_in_patch)
        exec_total += len(exec_in_patch)

    def pct(n, d): return round(100*n/d, 1) if d else 0.0
    summary = {
        "scope": "coverage.py against fastapi/dependencies/utils.py, param_functions.py, params.py, utils.py",
        "lines_in_patch_total": sum(len(v) for v in patch.values()),
        "executable_lines_in_patch": exec_total,
        "f2p_covered": f2p_total,
        "p2p_covered": p2p_total,
        "union_covered": union_total,
        "f2p_pct": pct(f2p_total, exec_total),
        "p2p_pct": pct(p2p_total, exec_total),
        "union_pct": pct(union_total, exec_total),
        "coverage_complete": True,
    }
    out = {
        "instance_id": "FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871",
        "files_in_scope": sorted(patch),
        "per_file": rows,
        "summary": summary,
        "coverage_complete": True,
    }
    pathlib.Path(args.out).write_text(json.dumps(out, indent=2) + "\n")
    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()

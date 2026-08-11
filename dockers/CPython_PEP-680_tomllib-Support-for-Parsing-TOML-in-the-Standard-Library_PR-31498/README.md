# LoLBench Instance: CPython PR-31498 (PEP 680: tomllib)

> **Requirement**: [PEP 680](https://peps.python.org/pep-0680/) — "tomllib: Support for Parsing TOML in the Standard Library"
> **Implementing PR**: [python/cpython#31498](https://github.com/python/cpython/pull/31498)
> **base_commit**: `0b5a573ce8e8e90daad4d24b215aabb7356f4fce`  (2022-03-08, parent of squash-merge commit `591f6754`)
> **Language mix**: pure Python (Lib/tomllib/*.py — 4 new modules, 818 lines) + 1-line addition to `Python/stdlib_module_names.h`

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — validated with augmented sidecar.** The 2026-06-15 P2P
> refresh validates the expanded `orig` and `union` suites with 50
> original P2P selectors in `p2p.txt` and leaves the 3 synthesized
> sidecar selectors in `p2p_aug.txt`. Historical mutant validation
> kills all 16 PEP-680 mutants. Coverage is 100.0% / 67.3% / 100.0%
> for `orig` / `aug` / `union` over the 508 executable
> `Lib/tomllib/*.py` lines in `solution.patch`.

> **Base-commit note.** GitHub reports the PR base as
> `89b13042fc…` for this row (PR-creation-time tip of main). PR-31498
> was squash-merged into main on 2022-03-08; the merge commit
> `591f6754…` has a single parent `4d95fa1a…`, and diffing against
> that parent isolates the PR contribution from ~2 weeks of unrelated
> drift on main. Both bases happen to apply this PR's patches cleanly,
> but `4d95fa1a` is the canonical "tree right before PEP 680 landed"
> and matches the diff used to derive solution / eval_tests / omitted
> patches. Same pattern as PEP-617 / PEP-634 / PEP-654 / PEP-669.

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 13 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 6 | 3 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 19 | 53 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

The current `eval.sh` wrapper does not expose a `--suite` flag. Run the image directly when you need a non-default suite:

```bash
docker run --rm \
  --network=none \
  --memory 7g --cpus 4 \
  -e LOLBENCH_SUITE=union \
  -v $(pwd)/solution.patch:/in/solution.patch:ro \
  -v $(pwd)/out:/out \
  lolbench/cpython-pr-31498:1
```

## 1. Bundle layout

```
dockers/CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498/
├── README.md
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
├── Dockerfile               ← lolbench/cpython-pr-31498:1
├── spec.json
├── solution.patch           ← 5 files (4 new Lib/tomllib/*.py + 1-line Python/stdlib_module_names.h)
├── eval_tests.patch         ← 80 files (Lib/test/test_tomllib/* incl. 74 .toml/.json fixtures)
├── omitted.patch            ← 5 files: Doc/tomllib.rst + 2 Doc edits + NEWS + .github/CODEOWNERS
├── f2p.txt                  ← 13 public-API / module-level methods (all from Lib/test/test_tomllib/)
├── p2p.txt                  ← 50 stable pre-existing methods (P2P/F2P = 3.85×)
├── eval_tests_aug.patch     ← sidecar augmentation: 2 new test modules
├── f2p_aug.txt              ← 6 mutation-killing public tomllib tests
├── p2p_aug.txt              ← 3 stability tests for unrelated stdlib behavior
├── test_augmentation/       ← source copies + audit.json
├── run_tests.sh
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← coverage.py bundle (Python-only; no gcov)
```

tomllib is pure Python. No SYS_PTRACE, no special caps; `--network=none`,
default seccomp.

---

## 2. Building the images

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-31498:1 .
docker build -t lolbench/cpython-pr-31498-coverage:1 -f coverage/Dockerfile .
```

The patches were derived from `git diff 4d95fa1a…591f6754`, split by
file role. No truncated cache files; no parser regeneration; no
generated tables. Patch math is straightforward: 5 (solution) + 80
(eval_tests) + 5 (omitted) = 90 PR files, matching
`data/pr_files_cache/...PR-31498.json`.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure mode

At pre-state, `Lib/tomllib/` does not exist. The test runner does
`unittest.TestLoader.loadTestsFromName("test.test_tomllib.test_data.TestData.test_invalid")`,
which imports the package `test.test_tomllib`. The package's
`__init__.py` does `import tomllib` — `ModuleNotFoundError` →
load-time error → ERROR. All 13 F2P methods ERROR the same way.

There is no syntactic obstacle: `eval_tests.patch` ships the test
files which parse fine at pre-state (no new syntax).

### 3.2 F2P (13 methods) — all from `Lib/test/test_tomllib/`

| Module | Class | # | What it exercises |
| --- | --- | ---: | --- |
| `test_data` | `TestData` | 2 | Iterates 50+ `.toml` fixtures under `data/valid/` and `data/invalid/`. `tomllib.loads(...)` on valid → compared via `burntsushi.convert/normalize` to the matching `.json` expected output; on invalid → `tomllib.TOMLDecodeError` is asserted. |
| `test_error` | `TestError` | 5 | Drives 5 error-path scenarios: line-and-col reporting, missing-value, invalid char in single-line literal, that `TOMLDecodeError.__module__ == tomllib.__name__`, and that `parse_float` returning a non-scalar raises `ValueError`. |
| `test_misc` | `TestMiscellaneous` | 6 | Exercises the rest of the surface: `tomllib.load(binary_file)`, type-error when given a text-mode file, `parse_float=Decimal`, `copy.deepcopy()` roundtrip, recursion-limit guard rails for arrays and inline tables (470 / 310 deep). |

All 13 methods exercise only the documented public surface:
`tomllib.loads`, `tomllib.load`, `tomllib.TOMLDecodeError`,
`tomllib.__name__`. No underscore-prefixed symbols from
`tomllib._parser` / `tomllib._re` / `tomllib._types` are referenced
directly by the test methods.

### 3.3 P2P (50 methods)

From four pre-existing test files that the PR does **not** touch:

| File / Class | # |
| --- | ---: |
| `test_grammar.TokenTests` | 7 |
| `test_grammar.GrammarTests` | 17 |
| `test_ast.AST_Tests` | 7 |
| `test_ast.ASTHelpers_Test` | 5 |
| `test_ast.ConstantTests` | 2 |
| `test_ast.EndPositionTests` | 2 |
| `test_sys.SysModuleTest` | 4 |
| `test_module.ModuleTests` | 6 |

All four files are absent from the PR diff. Ratio P2P/F2P = 3.85×.

The `test_sys.SysModuleTest.test_module_names` /
`test_stdlib_dir` and `test_module.ModuleTests.test_uninitialized` /
`test_module_getattr` / `test_module_dir` selections were added per
Codex L1 review to make P2P locality stronger: these tests exercise
the module-object + `sys.stdlib_module_names` machinery that
`solution.patch`'s `Python/stdlib_module_names.h +1` line directly
touches, while staying byte-identical pre/post (the tests only
assert type/structural invariants, not contents-of-stdlib-module-names).

### 3.4 Out-of-scope

- **`tomllib._parser.*` / `tomllib._re.*` / `tomllib._types.*`** —
  implementation-internal helpers behind `_`-prefixed names. The PR
  makes them private on purpose; F2P that requires them would over-
  constrain agents. None of the 13 F2P methods reach into these
  modules directly.

There are no allowlisted private symbols for this instance.

---

## 4. Augmented sidecar

The augmented sidecar is opt-in via `LOLBENCH_SUITE=aug` or
`LOLBENCH_SUITE=union`; `orig` preserves the historical bundle.
`eval_tests_aug.patch` creates only new files:

- `Lib/test/test_tomllib_aug.py`: 6 public-API F2P selectors covering
  `tomllib.load`, `tomllib.loads`, `parse_float`, duplicate-key and
  frozen-namespace errors, invalid string/comment inputs, booleans,
  arrays, datetimes, dates, and non-decimal integers. These selectors
  kill all 16 committed PEP-680 mutants.
- `Lib/test/test_tomllib_stability_aug.py`: 3 P2P selectors that do not
  import `tomllib`; they pin unrelated public `json`, `configparser`,
  and `datetime` behavior under the PEP's `Backwards Compatibility`
  section.

`spec.json.augmented.triage` records one triage entry per selector, and
every `requirement_sections` string exactly matches the
`Section Classification Summary` table in
`requirement_pr_pairs/CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498.md`.

---

## 5. Validation status

P2P expansion refreshed on 2026-06-15:

- `orig/pre`: 13 F2P ERROR, 50 P2P PASS.
- `orig/post`: 13 F2P PASS, 50 P2P PASS, `resolved=true`.
- `union/pre`: 19 F2P ERROR, 53 P2P PASS.
- `union/post`: 19 F2P PASS, 53 P2P PASS, `resolved=true`.
- `aug` selectors are unchanged from the validated sidecar: 6 F2P and
  3 synthesized P2P selectors.
- Historical mutant arm: all 16 committed PEP-680 mutants are killed
  by at least one union F2P selector.
- Coverage refreshed for all suites: `orig` 100.0%, `aug` 67.3%, and
  `union` 100.0% over 508 executable `Lib/tomllib/*.py` lines. The
  original suite already covers the full executable patch surface, so
  the augmentation's primary contribution is mutation killing.

---

## 6. Troubleshooting

See `docs/executable_environment_plan.md` §17. PEP-680 specifics:

- **Pure-Python coverage**: coverage measurement uses `coverage.py`
  rather than gcov. The coverage Dockerfile installs `coverage==7.4.4`
  via pip against the freshly-built `./python`, so the tracer runs
  under the same interpreter that runs the tests. `compute_coverage.py`
  parses coverage.py's per-file JSON.
- **base_commit vs GitHub PR-base**: same pattern as prior CPython
  instances — use the merge parent `4d95fa1a…`. Both bases happen to
  work here, but `4d95fa1a` is canonical (parent of squash-merge
  commit).
- **`Python/stdlib_module_names.h` (+1 line)**: triggers `make`'s
  `regen-frozen` dependency; the build picks it up automatically. No
  C source files are modified by the PR.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `7g`
- Timeout: `not recorded` seconds
- Eval-time network: disabled with `--network=none`.


<!-- LoLBench audit completeness sections -->

## Bundle file map

| Path | Purpose |
| --- | --- |
| `README.md` | bundle documentation |
| `eval.sh` | evaluator-facing wrapper |
| `validate.sh` | pre/post validation wrapper |
| `Dockerfile` | correctness eval image recipe |
| `spec.json` | instance metadata and selector contract |
| `solution.patch` | reference implementation patch for validation |
| `eval_tests.patch` | hidden original eval tests |
| `eval_tests_aug.patch` | hidden augmented eval tests |
| `omitted.patch` | excluded PR hunks |
| `f2p.txt` | original fail-to-pass selectors |
| `p2p.txt` | original pass-to-pass selectors |
| `f2p_aug.txt` | augmented fail-to-pass selectors |
| `p2p_aug.txt` | augmented pass-to-pass selectors |
| `run_tests.sh` | container test runner |
| `coverage/` | coverage image recipe and scripts |
| `coverage_out/` | coverage reports |
| `test_augmentation/` | augmentation audit/source notes |

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**100.0% / 67.3% / 100.0%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

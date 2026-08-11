# LoLBench Instance: CPython PR-101441 (PEP 709: Inlined Comprehensions)

> **Requirement**: [PEP 709](https://peps.python.org/pep-0709/) — "Inlined Comprehensions"
> **Implementing PR**: [python/cpython#101441](https://github.com/python/cpython/pull/101441)
> **base_commit**: `0aeda297931820436a50b78f4f7f0597274b5df4`  (parent of squash-merge commit `c3b595e7`)
> **Language mix**: 16 C source/header files (compile.c, symtable.c, bytecodes.c, flowgraph.c, assemble.c, generated_cases.c.h, opcode_*.h, frameobject.c, pycore_*.h, _testinternalcapi.c) + 2 Python files (Lib/opcode.py + Lib/importlib/_bootstrap_external.py for the bytecode magic-number bump)

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — validated.** The original P2P set was expanded to 50
> pre-existing CPython regression selectors and revalidated on 2026-06-15.

> **Base-commit note.** Same merge-parent override as prior CPython
> instances (PEP-617/634/654/669/680/615). See `spec.json.base_commit_note`.

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 7 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 16 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 23 | 54 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

The current `eval.sh` wrapper does not expose a `--suite` flag. Run the image directly when you need a non-default suite:

```bash
docker run --rm \
  --network=none \
  --memory 7g --cpus 4 \
  -e LOLBENCH_SUITE=union \
  -v $(pwd)/solution.patch:/in/solution.patch:ro \
  -v $(pwd)/out:/out \
  lolbench/cpython-pr-101441:1
```

## 1. Bundle layout

```
dockers/CPython_PEP-709_Inlined-comprehensions_PR-101441/
├── README.md
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
├── Dockerfile               ← lolbench/cpython-pr-101441:1
├── spec.json
├── solution.patch           ← 18 files (16 C/header + 2 Python)
├── eval_tests.patch         ← 6 modified test files (test_compile.py + test_trace.py for F2P; the others stay for fidelity)
├── omitted.patch            ← 3 files: Doc/dis.rst + whatsnew + NEWS
├── f2p.txt                  ← 7 behavioral-change methods (test_compile + test_trace)
├── p2p.txt                  ← 50 stable public-API methods (P2P/F2P = 7.14×)
├── run_tests.sh
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← hybrid coverage.py + gcov bundle (2 Py + 16 C)
```

No special caps; `--network=none`, default seccomp.

---

## 2. Building the images

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-101441:1 .
docker build -t lolbench/cpython-pr-101441-coverage:1 -f coverage/Dockerfile .
```

Patches derived from `git diff 0aeda297…c3b595e7`. Patch math:
18 (solution) + 6 (eval_tests) + 3 (omitted) = 27 PR files, matching
both `data/pr_files_cache/...PR-101441.json` and
`data/pr_file_cache_extended/...PR-101441.json`.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure mode

PEP 709 *preserves* legacy comprehension scoping while inlining the
synthetic function frame away. So tests that just check classic
comp behavior (late-binding lambdas, default-arg captures,
NameError vs UnboundLocalError, etc.) pass at BOTH pre- and post-
states — they're regression locks for the rewrite, not valid F2P.

What *does* observably change is the **bytecode shape** (LIST_APPEND
now lives in the parent code object, not in a synthetic comp code
object's `co_consts[0]`) and the **trace event count** (no extra
trace event for the synthetic listcomp call). The 7 F2P selectors
in this bundle all assert on one of those two observable changes.

### 3.2 F2P (7 methods)

| Selector | Pre-state failure mode |
| --- | --- |
| `test_compile.TestSourcePositions.test_multiline_list_comprehension` | LIST_APPEND not found at expected position in module code object (it lives in `co_consts[0]` pre-state) |
| `test_compile.TestSourcePositions.test_multiline_async_list_comprehension` | LIST_APPEND not found in async function code (it lives in `co_consts[1]`); also RETURN_VALUE→RETURN_CONST mismatch |
| `test_compile.TestSourcePositions.test_multiline_set_comprehension` | SET_ADD not in module code object |
| `test_compile.TestSourcePositions.test_multiline_async_set_comprehension` | SET_ADD not in async function code |
| `test_compile.TestSourcePositions.test_multiline_dict_comprehension` | MAP_ADD not in module code object |
| `test_compile.TestSourcePositions.test_multiline_async_dict_comprehension` | MAP_ADD not in async function code |
| `test_trace.TestLineCounts.test_trace_list_comprehension` | line-event count is 12 (extra event for synthetic call); test asserts 11 |

All 7 use only public CPython APIs (`compile()`, `dis.get_instructions()`,
`sys.settrace`, `trace.Trace`). No internal symbols.

### 3.3 Why the 20 `ListComprehensionTest` methods are NOT F2P

Codex round 1 verified empirically on Python 3.9.13 that all 20 new
`ListComprehensionTest.test_*` methods PASS at pre-state. They are
**regression locks** the PR author added to ensure the inlined
implementation preserves classic comp scoping semantics — not
behavioral validators. Examples:

- `test_lambdas_with_free_var` — classic late-binding `[4,4,4,4,4]`;
  passes at both states.
- `test_lambdas_with_iteration_var_as_default` — default-arg trick;
  passes at both states.
- `test_nameerror`, `test_unbound_local_*` — old behavior for these
  diagnostic exceptions is unchanged by PEP 709.

The test bodies remain in `eval_tests.patch` for fidelity (the whole
file is rewritten from doctest to unittest), but are recorded in
`spec.json.out_of_scope_surfaces` as deliberately excluded.

### 3.4 P2P (50 methods)

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

Ratio P2P/F2P = 7.14×.

### 3.5 Out-of-scope + allowlist

Out-of-scope:
- 20 `ListComprehensionTest` regression locks (see §3.3).
- Internal compiler helpers: `_PyComp_*`, `INLINED_COMP_*`.

Allowlisted private symbols (`spec.json.public_surface_allowlist`):
- **`sys._getframe`** — referenced by P2P `test_sys.test_getframe`.
  Documented CPython implementation detail.

---

## 4. Validation status

The expanded original P2P set was validated on 2026-06-15:

- **pre-state** (base + `eval_tests.patch`): 7 F2P FAIL; 50 P2P PASS.
- **post-state orig** (base + `solution.patch` + `eval_tests.patch`): 7
  F2P + 50 P2P PASS, `resolved=true`.
- **post-state union**: 23 F2P + 54 P2P PASS, `resolved=true`.

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17.

- **Hybrid coverage**: `coverage.py 7.4.4` for the 2 Python files;
  `gcov + gcovr` for the 16 C/header files (with multi-pattern
  `--filter` to isolate the PEP-709 set from the rest of CPython).
- **No reconfigure needed**: PEP-709 does not touch `configure.ac` /
  `Makefile.pre.in` / `pyconfig.h.in`. `make` alone rebuilds the
  touched .c files.
- **base_commit override**: `0aeda297…` (merge parent), same as
  prior CPython instances.
- **F2P pruning history**: round 1 picked all 20 ListComprehensionTest
  methods; Codex caught them as regression locks (empirical verification
  on Py 3.9). Replaced with the 7 behavioral-change tests above.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 81.3%, 170/209, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. Prefer the union report when augmented tests are available.

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

**72.73% / 81.34% / 81.34%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

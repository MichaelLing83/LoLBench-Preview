# LoLBench Instance: CPython PR-116129 (PEP 696: Type Defaults for Type Parameters)

> **Requirement**: [PEP 696](https://peps.python.org/pep-0696/) — "Type Defaults for Type Parameters"
> **Implementing PR**: [python/cpython#116129](https://github.com/python/cpython/pull/116129)
> **base_commit**: `852263e1086748492602a90347ecc0a3925e1dda`  (parent of squash-merge `ca269e58`)
> **Language mix**: 13 C source/header files (parser.c, compile.c, symtable.c, ast.c, Python-ast.c, intrinsics.c, _typingmodule.c, typevarobject.c, plus internal headers) + 2 Python files (typing.py, ast.py) + 2 grammar/schema sources (Grammar/python.gram, Parser/Python.asdl)

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance.

> **Status — bundle authored offline; not yet validated.**
> `spec.json.validated_at` is `null`.

> **Base-commit note.** Same merge-parent override as prior CPython
> instances. See `spec.json.base_commit_note`.

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 29 | 61 |
| `aug` | mutation/coverage-driven sidecar selectors only | 17 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 46 | 65 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## 1. Bundle layout

```
dockers/CPython_PEP-696_..._PR-116129/
├── README.md
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
├── Dockerfile               ← lolbench/cpython-pr-116129:1
├── spec.json
├── solution.patch           ← 17 files (13 C/header + 2 Python + 2 grammar/schema)
├── eval_tests.patch         ← 4 modified test files (test_type_params + test_typing + test_ast + test_unparse)
├── omitted.patch            ← 7 files (5 Doc + NEWS + Tools/c-analyzer tsv)
├── f2p.txt                  ← 29 behavioral-change methods
├── p2p.txt                  ← 61 stable public-API methods (P2P/F2P = 2.10×)
├── run_tests.sh
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← hybrid coverage.py + gcov bundle (2 Py + 13 C)
```

No special caps; `--network=none`, default seccomp.

---

## 2. Building the images

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-116129:1 .
docker build -t lolbench/cpython-pr-116129-coverage:1 -f coverage/Dockerfile .
```

Patches derived from `git diff 852263e1…ca269e58`. Patch math:
17 + 4 + 7 = 28 PR files.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure mode

The 29 F2P methods all exercise PEP-696's new observable behavior:

- **`class C[T = int]:` / `def f[T = int]():` / `type Alias[T = int] = ...` syntax** — added by the parser changes. Pre-state: parser rejects → SyntaxError at `exec()` / `ast.parse()` time inside the test.
- **`typing.NoDefault` sentinel** — new module-level object. Pre-state: AttributeError on import.
- **`typing.TypeVar(default=...)`, `typing.ParamSpec(default=...)`, `typing.TypeVarTuple(default=...)`** — new kwarg on the constructors. Pre-state: TypeError ("unexpected keyword argument 'default'").
- **`ast.TypeVar.default` field** — new ast node field. Pre-state: missing field → AttributeError or wrong unparse output.

The test files themselves PARSE FINE at pre-state — all new-syntax literals are inside Python string arguments (`exec("class C[T=int]: pass")`, `ast.parse("...")`, etc.).

### 3.2 F2P (29 methods)

| Source | # | What it exercises |
| --- | ---: | --- |
| `test_type_params.DefaultsTest` | 9 | parser + compile + symtable for `T = default` in class/def/type-alias headers |
| `test_typing.NoDefaultTests` | 3 | `typing.NoDefault` sentinel: constructor / repr / pickle / no-call |
| `test_typing.TypeParameterDefaultsTests` | 13 | `default=` kwarg on TypeVar/ParamSpec/TypeVarTuple + specialization |
| `test_ast.AST_Tests` | 1 | `ast.parse(..., feature_version=...)` gating of the new syntax |
| `test_unparse` | 3 | `ast.unparse` emission for type-param `default` field |

All 29 use only public CPython surface: `exec()`, `ast.parse()`,
`ast.unparse()`, `typing.TypeVar/ParamSpec/TypeVarTuple/NoDefault`.

### 3.3 P2P (61 methods)

From 5 pre-existing test files that the PR does **not** touch:

| File / Class | # |
| --- | ---: |
| `test_grammar.TokenTests` | 7 |
| `test_grammar.GrammarTests` | 23 |
| `test_int.IntTestCases` | 5 |
| `test_int.IntStrDigitLimitsTests` | 3 |
| `test_float.GeneralFloatCases` | 5 |
| `test_float.IEEEFormatTestCase` | 3 |
| `test_float.FormatFunctionsTestCase` | 1 |
| `test_string.ModuleTest` | 5 |
| `test_string.TestTemplate` | 5 |
| `test_sys.SysModuleTest` | 4 |

Ratio P2P/F2P = 2.10×.

### 3.4 Out-of-scope + allowlist

- **Out-of-scope**: internal helpers (`_PyTypeVar_*`,
  `INTRINSIC_SET_TYPEPARAM_DEFAULT`, etc.) — F2P checks observable
  public behavior only.
- **Allowlist**: `sys._getframe` — referenced by P2P
  `test_sys.test_getframe`. Documented CPython implementation detail.

---

## 4. Validation status

`spec.json.validated_at` is `null`. The §7 invariant will be confirmed
by running `./validate.sh` after this bundle is approved.

Expected:
- **pre-state**: 29 F2P FAIL/ERROR; 61 P2P PASS.
- **post-state**: 29 F2P + 61 P2P PASS, `resolved=true`.

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17.

- **Hybrid coverage**: `coverage.py 7.4.4` for `Lib/typing.py` + `Lib/ast.py`; `gcov + gcovr` for the 13 C files.
- **No reconfigure needed**: PEP-696 does not touch `configure.ac` / `Makefile.pre.in`. `make` regenerates `parser.c` + `Python-ast.c` from `Grammar/python.gram` + `Parser/Python.asdl`.
- **base_commit override**: `852263e1…` (merge parent).

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 85.3%, 372/436, coverage_complete=true

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

**72.71% / 82.11% / 85.32%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

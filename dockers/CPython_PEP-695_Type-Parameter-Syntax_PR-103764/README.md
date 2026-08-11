# LoLBench Instance: CPython PR-103764 (PEP 695: Type Parameter Syntax)

> **Requirement**: [PEP 695](https://peps.python.org/pep-0695/) — "Type Parameter Syntax"
> **Implementing PR**: [python/cpython#103764](https://github.com/python/cpython/pull/103764)
> **base_commit**: `fdafdc235e74f2f4fedc1f745bf8b90141daa162`  (parent of squash-merge `24d8b884`)
> **Language mix**: 34 C source/header files (parser, AST, compile, symtable, opcodes, typevarobject + many internal headers) + 5 Python files (typing.py, ast.py, keyword.py, opcode.py, importlib/_bootstrap_external.py) + 2 grammar/schema sources

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
| `orig` | original PR-derived hidden selectors | 88 | 180 |
| `aug` | mutation/coverage-driven sidecar selectors only | 12 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 100 | 184 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## 1. Bundle layout

```
dockers/CPython_PEP-695_Type-Parameter-Syntax_PR-103764/
├── README.md
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
├── Dockerfile               ← lolbench/cpython-pr-103764:1
├── spec.json
├── solution.patch           ← 44 files (34 C/header + 5 Python + 2 grammar/schema + 3 Linux build glue)
├── eval_tests.patch         ← 7 modified test files (2 NEW: test_type_params, test_type_aliases)
├── omitted.patch            ← 5 files (Doc + NEWS + 3 PCbuild Windows-only)
├── f2p.txt                  ← 88 behavioral-change methods (PR's full test contribution)
├── p2p.txt                  ← 180 stable public-API methods (P2P/F2P = 2.05×)
├── run_tests.sh
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← hybrid coverage.py + gcov bundle (5 Py + 34 C)
```

No special caps; `--network=none`, default seccomp.

---

## 2. Building the images

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-103764:1 .
docker build -t lolbench/cpython-pr-103764-coverage:1 -f coverage/Dockerfile .
```

Patches derived from `git diff fdafdc23…24d8b884`. Patch math:
44 + 7 + 5 = 56 PR files.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure mode

The 88 F2P selectors all exercise PEP-695's new syntax:

- **`class C[T, *Ts, **P]:`, `def f[T, *Ts, **P]():`** — PEP-695 type parameter clauses on classes/functions.
- **`type Alias[T] = ...`** — PEP-695 type-alias statement (new keyword `type`).

Two distinct pre-state failure modes:

- **test_type_params.py module-level**: the NEW file has module-level
  `def global_generic_func[T]():` (line 401) and `class GlobalGenericClass[T]:`
  (line 404) statements. At base_commit, parser rejects `[T]` → SyntaxError
  at *module import* → every test method ERRORs at unittest load time.
- **test_type_aliases.py + test_ast**: the file bodies parse fine at
  pre-state (no module-level new syntax), but each test method
  `exec()`s or `ast.parse()`s a snippet containing `type Alias[T] = ...`
  or `class C[T]: pass` → SyntaxError during the test → FAIL/ERROR.

### 3.2 F2P (88 methods — PR's full test contribution)

| Source | # | What it exercises |
| --- | ---: | --- |
| `test_type_params.TypeParamsInvalidTest` | 4 | Syntax error / name-collision rules |
| `test_type_params.TypeParamsNonlocalTest` | 2 | Nonlocal binding rules in type-param scope |
| `test_type_params.TypeParamsAccessTest` | 7 | Where the type params are visible (class / function / method / nested / super) |
| `test_type_params.TypeParamsLazyEvaluationTest` | 2 | Lazy evaluation semantics for type-param annotations |
| `test_type_params.TypeParamsClassScopeTest` | 4 | Class-body scoping (alias / bound / explicit global) |
| `test_type_params.TypeParamsManglingTest` | 1 | Name mangling for `__x` style names |
| `test_type_params.TypeParamsComplexCallsTest` | 1 | Complex generic-default expressions |
| `test_type_params.TypeParamsTraditionalTypeVarsTest` | 2 | Compatibility with `typing.TypeVar` |
| `test_type_params.TypeParamsTypeVarTest` | 2 | TypeVar created by `[T]` syntax |
| `test_type_params.TypeParamsTypeVarTupleTest` | 1 | `[*Ts]` syntax |
| `test_type_params.TypeParamsTypeVarParamSpecTest` | 1 | `[**P]` syntax |
| `test_type_params.TypeParamsTypeParamsDunder` | 2 | `.__type_params__` attribute on class/function |
| `test_type_aliases.TypeParamsInvalidTest` | 1 | Syntax errors in `type Alias[T] = ...` |
| `test_type_aliases.TypeParamsAccessTest` | 2 | Alias-level scope visibility |
| `test_type_aliases.TypeParamsAliasValueTest` | 2 | Alias value computation + repr |
| `test_type_aliases.TypeAliasConstructorTest` | 2 | `typing.TypeAliasType(...)` constructor |
| `test_type_aliases.TypeAliasTypeTest` | 2 | TypeAliasType public-API contract (immutable, no subclassing) |
| `test_ast.AST_Tests` | 1 | `ast.parse` feature_version gating for `class X[T]:` syntax |

All 88 use only public CPython surface: `exec()` / `run_code()` /
`ast.parse()` on Python source + `typing.TypeVar / TypeVarTuple /
ParamSpec / TypeAliasType` + class/def `__type_params__` attribute.

### 3.3 P2P (180 methods)

From 7 pre-existing test files the PR does **not** touch:

| File / Class | # |
| --- | ---: |
| `test_grammar.TokenTests + GrammarTests` | 30 |
| `test_int.IntTestCases + IntStrDigitLimitsTests` | 8 |
| `test_float.GeneralFloatCases + IEEEFormatTestCase + FormatFunctionsTestCase` | 9 |
| `test_string.ModuleTest + TestTemplate` | 10 |
| `test_calendar.OutputTestCase + CalendarTestCase` | 10 |
| `test_list.ListTest` | 4 |
| `test_dict.DictTest` | 10 |

Ratio P2P/F2P = 2.05×.

### 3.4 Out-of-scope

- Internal helpers (`_PyTypeVar_*`, `_PyTypeAlias_*`,
  `INTRINSIC_SET_FUNCTION_TYPE_PARAMS`, etc.) — F2P checks observable
  public behavior only.

No allowlisted private symbols for this instance.

---

## 4. Validation status

`spec.json.validated_at` is `null`. The §7 invariant will be confirmed
by running `./validate.sh` after this bundle is approved.

Expected:
- **pre-state**: 88 F2P FAIL/ERROR; 180 P2P PASS.
- **post-state**: 88 F2P + 180 P2P PASS, `resolved=true`.

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17.

- **Hybrid coverage**: `coverage.py 7.4.4` for 5 Python files (typing.py, ast.py, keyword.py, opcode.py, importlib/_bootstrap_external.py); `gcov + gcovr` for 34 C source/header files (parser/AST/compile/symtable/typevarobject + many internal headers).
- **No reconfigure needed**: PEP-695 does not touch `configure.ac` / `pyconfig.h.in`. `make` regenerates `parser.c` + `Python-ast.c` from `Grammar/python.gram` + `Parser/Python.asdl`. `Makefile.pre.in`, `Modules/Setup.bootstrap.in`, and `Modules/Setup.stdlib.in` are in **solution.patch** (moved out of omitted.patch in round 1 per Codex C1 — they add `Objects/typevarobject.o` to `OBJECT_OBJS` and wire `_typing` to bootstrap; without them the build links incorrectly).
- **base_commit override**: `fdafdc23…` (merge parent), same as prior CPython instances.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 81.9%, 1034/1263, coverage_complete=true

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

**68.2% / 78.1% / 81.9%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

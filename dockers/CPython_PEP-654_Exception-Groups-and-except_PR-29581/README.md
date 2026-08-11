# LoLBench Instance: CPython PR-29581 (PEP 654)

> **Requirement**: [PEP 654](https://peps.python.org/pep-0654/) — "Exception Groups and except*"
> **Implementing PR**: [python/cpython#29581](https://github.com/python/cpython/pull/29581)
> **base_commit**: `850aefc2c651110a784cd5478af9774b1f6287a3`  (2021-12-09, parent of merge commit `d60457a6`)
> **Language mix**: C (Grammar/parser/AST/compile/ceval/ExceptionGroup machinery) + Python (Lib/ast.py, Lib/opcode.py, importlib)

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — validated 2026-05-21.** Original, augmented, and union
> suites pass the §7 invariant. Union coverage of hand-authored C/H
> solution lines is 88.1% (385/437), above the 80% gate. Original
> coverage is 79.6% (348/437). Image `lolbench/cpython-pr-29581:1`
> on docker engine 29.4.3 / darwin/arm64.

> **Base-commit note.** GitHub reports the PR base as
> `b9310773…` for this row (PR-creation-time tip, 2021-12). The PR
> was rebased before merge — the parent of merge commit `d60457a6…`
> is `850aefc2…`, and patches apply cleanly only against that commit.
> Same pattern as the PEP-617 and PEP-634 instances. Recorded in
> `spec.json.base_commit_note`.

---

## TL;DR — evaluate a solution

```bash
./eval.sh path/to/your/solution.patch
```

Prints a one-line verdict and writes `eval_out/agent_report.json`.
Exit code is `0` iff resolved (F2P + P2P all pass).

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 50 | 59 |
| `aug` | mutation/coverage-driven sidecar selectors only | 10 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 60 | 63 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

The current `eval.sh` wrapper does not expose a `--suite` flag. Run the image directly when you need a non-default suite:

```bash
docker run --rm \
  --network=none \
  --memory 7g --cpus 4 \
  -e LOLBENCH_SUITE=union \
  -v $(pwd)/solution.patch:/in/solution.patch:ro \
  -v $(pwd)/out:/out \
  lolbench/cpython-pr-29581:1
```

## 1. Bundle layout

```
dockers/CPython_PEP-654_Exception-Groups-and-except_PR-29581/
├── README.md                ← this file
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
│
├── Dockerfile               ← layer-3 eval image (lolbench/cpython-pr-29581:1)
├── spec.json                ← instance metadata + F2P/P2P + triage
├── solution.patch           ← 19 files (Grammar + Parser/parser.c regen + ASDL + ast/compile/ceval + ExceptionGroup machinery)
├── eval_tests.patch         ← 8 test files (NEW test_except_star.py + 7 modifications)
├── eval_tests_aug.patch     ← sidecar tests: 10 new F2P + 4 new P2P
├── omitted.patch            ← 7 files: docs + NEWS + 3 test files whose bodies have literal except*
├── f2p.txt                  ← 50 system tests (49 test_except_star + 1 test_unparse roundtrip)
├── p2p.txt                  ← 59 stable test_grammar.py + test_ast.py methods (P2P/F2P = 1.18×)
├── f2p_aug.txt              ← augmented F2P selectors
├── p2p_aug.txt              ← augmented P2P selectors
├── run_tests.sh             ← container entrypoint
├── test_augmentation/       ← augmented test sources + audit metadata
│
├── base/                    ← layer-2 base image (reused with the PEP-768/617/634 instances)
│   └── Dockerfile             lolbench/cpython-base:1
│
└── coverage/                ← curation-time gcov bundle (separate one-shot image)
    ├── Dockerfile             lolbench/cpython-pr-29581-coverage:1 (Debug + --coverage)
    ├── run_coverage.sh        applies both patches, rebuilds instrumented, runs F2P + P2P, snapshots .gcda
    └── compute_coverage.py    parses solution.patch + gcovr JSON
```

### Capabilities

PEP 654 runs entirely in-process (no `process_vm_readv`, no
cross-process attach). `eval.sh` and `validate.sh` do **not** add
`--cap-add=SYS_PTRACE`; the container runs with `--network=none` and
the default seccomp profile.

---

## 2. Building the images

```bash
# layer-2 base (already built for PEP-768/617/634; reused)
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/

# layer-3 eval image
docker build -t lolbench/cpython-pr-29581:1 .

# (optional, one-time) coverage image — Debug + gcov
docker build -t lolbench/cpython-pr-29581-coverage:1 -f coverage/Dockerfile .
```

The patches were derived from `git diff 850aefc2…d60457a6` (merge
parent and PR-29581 merge commit), then split by file role per the
plan's §1 contract. `Parser/parser.c` (+2770/−1826 lines, regenerated
PEG parser table) was reconstructed from the local clone since the
GitHub-API patch field is empty for very large diffs.

Reconstruction validation: solution.patch ∪ eval_tests.patch ∪
omitted.patch equals the full PR file set (34 files), all three apply
cleanly via `git apply --check` against `base_commit`, and the
post-state applies cleanly on top.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure modes

At pre-state (`base_commit + eval_tests.patch` only):

- **test_except_star.py** uses `try ... except* X: ...` syntax at module
  level. The pre-PR PEG parser does not recognise `except*` as a
  statement form → `SyntaxError` during module load → all 49
  `TestExceptStar*` methods ERROR (loadTestsFromName fails).
- **test_unparse.UnparseTestCase.test_try_except_star_finally** calls
  `self.check_ast_roundtrip(source)` where `source` contains
  `try/except*/finally`. `ast.parse` on except* → `SyntaxError` →
  test ERRORS.

All 50 F2P transitions are clean ERROR → PASS through the §6.4 gate.

### 3.2 F2P (50 methods) — system tests only

**Group A — 49 methods from the new `test.test_except_star.*` test classes**, added wholesale by the PR (Lib/test/test_except_star.py, 976 lines). Each method exercises one specific PEP 654 case through actual Python `try/except*` syntax and real exception raising/catching:

| Class | # methods | Public surface |
| --- | ---: | --- |
| `TestInvalidExceptStar` | 4 | `except*` with mixed except/except*, invalid exception types, ExceptionGroup-as-except* type |
| `TestBreakContinueReturnInExceptStarBlock` | 5 | control-flow validation inside except* blocks |
| `TestExceptStarSplitSemantics` | 18 | how ExceptionGroup splits across except* handlers |
| `TestExceptStarReraise` | 8 | reraising from inside except* (named + unnamed) |
| `TestExceptStarRaise` | 6 | raising new exceptions inside except* |
| `TestExceptStarRaiseFrom` | 6 | `raise ... from ...` semantics inside except* |
| `TestExceptStarExceptionGroupSubclass` | 1 | except* with ExceptionGroup subclasses |
| `TestExceptStarCleanup` | 1 | sys.exc_info restoration after except* |

**Group B — 1 system test from test_unparse.py**:

| Test | What it exercises |
| --- | --- |
| `UnparseTestCase.test_try_except_star_finally` | `ast.parse(SRC) → ast.unparse(tree) → ast.parse(roundtrip)` for try/except*/finally. Public ast API surface. |

### 3.3 P2P (59 methods)

All from `Lib/test/test_grammar.py` (37) and `Lib/test/test_ast.py` (22). The selected methods are byte-identical between pre- and post-state, but the two files reach that property by different routes:

- **`test_grammar.py` is moved to `omitted.patch`** — the file is NOT in `eval_tests.patch` and therefore stays unmodified at both states. The PR-added `test_try_star` method has literal `except*` syntax in its body which would prevent the pre-state Python parser from importing the whole module.
- **`test_ast.py` IS in `eval_tests.patch`** — the file gets the PR's modifications. The chosen P2P methods, however, avoid the two PR-affected code paths: (a) the +1 line in `_assertTrueorder` is only reached by `AST_Tests.test_snippets`, which is excluded from P2P, and (b) the new `ASTValidatorTests.test_try_star` method is excluded from P2P. All chosen methods are byte-identical between pre/post.

| Class | # | Examples |
| --- | ---: | --- |
| `test_grammar.TokenTests` | 6 | `test_backslash`, `test_ellipsis`, `test_floats`, `test_plain_integers`, `test_long_integers`, `test_string_literals` |
| `test_grammar.GrammarTests` | 31 | `test_funcdef`, `test_lambdef`, control flow (`test_if`/`while`/`for`/`try`/`with_statement`/`async_await`), declarations (`test_del_stmt`/`pass_stmt`/`return`/`raise`/`yield`/`import`/`global`/`nonlocal`/`break_stmt`/`continue_stmt`), expressions (`test_atoms`/`comparison`/`shift_ops`/`multiplicative_ops`), comprehensions, annotations, `test_classdef` |
| `test_ast.AST_Tests` | 4 | `test_AST_objects`, `test_AST_garbage_collection`, `test_slice`, `test_from_import` |
| `test_ast.ASTHelpers_Test` | 7 | `test_parse`, `test_parse_in_error`, `test_dump`, `test_dump_indent`, `test_dump_incomplete`, `test_copy_location`, `test_increment_lineno` |
| `test_ast.ConstantTests` | 7 | `test_validation`, `test_singletons`, `test_values`, `test_assign_to_constant`, `test_get_docstring`, `test_load_const`, `test_literal_eval` |
| `test_ast.EndPositionTests` | 4 | `test_lambda`, `test_func_def`, `test_call`, `test_class_def` |

All 59 method names AST-walk verified against the cloned source tree
at `base_commit`. Ratio P2P/F2P = 1.18×.

### 3.4 Augmented sidecar tests

`eval_tests_aug.patch` adds two opt-in test files with 14 selectors without
modifying the original `eval_tests.patch`, `f2p.txt`, or `p2p.txt`.
Run them with `LOLBENCH_SUITE=aug`, or run the combined suite with
`LOLBENCH_SUITE=union`.

| Suite | New tests | Purpose |
| --- | ---: | --- |
| F2P | 10 | Kills all 20 committed PEP-654 mutants and raises solution-line coverage above 80% through public `except*`, `ExceptionGroup`, `ast`, `compile`, `dis`, and `opcode` surfaces. |
| P2P | 4 | Pins unchanged ordinary `try/except`, exception chaining, regular `ast.unparse`, and `sys.exc_info()` behavior from the Backwards Compatibility surface. |

### 3.5 Out-of-scope tests

The PR adds + modifies tests beyond what's in F2P. The following are
deliberately excluded — see `spec.json.out_of_scope_surfaces` for full
rationale:

- **`test_ast.ASTValidatorTests.test_try_star`** — constructs
  `ast.TryStar(...)` nodes directly and feeds them to the internal AST
  validator (`self.stmt(t, '...')`). The validator is a private
  CPython facility; user code goes through `ast.parse`. This is
  unit-level: directly tests an internal symbol path. *Excluded per the
  no-unit-tests rule.*
- **`test_compile.TestStackSizeStability.test_try_except_star_{qualified,as,finally}`** —
  the class name says it: tests internal `code.co_stacksize` stability
  across repetitions of a snippet, an implementation invariant unrelated
  to user-visible except* behavior. *Excluded as borderline unit-flavored.*
- **`test_exception_group.TestSubgroup.test_basics_subgroup_split__bad_arg_type`** —
  exercises the pre-existing `BaseExceptionGroup.subgroup()` arg
  validation (the BaseExceptionGroup class was added earlier, not by
  this PR). Out of scope for **this** PR's F2P.
- **`test_exceptions.testSyntaxErrorOffset` (+2 lines)** — adds
  `check('try:\n  pass\nexcept*:\n  pass', 3, 8)`-style assertions on
  SyntaxError line/column coordinates. Both pre and post state raise
  SyntaxError on except*, but at different columns; precise offset
  matching across CPython versions is brittle. *Excluded as potential
  flaky F2P.*
- **`test_syntax.py` (+100 lines)** — doctest-format SyntaxError-message
  assertions. doctest-driven F2P is tricky to score via
  `unittest.TestLoader`; coverage of except* parser error messages is
  already provided by `TestInvalidExceptStar` (in F2P).
- **`test_grammar.GrammarTests.test_try_star`, `test_exception_variations.py`, `test_sys_settrace.py`** —
  their PR-added bodies contain literal `except*` syntax; applying
  them via `eval_tests.patch` would break pre-state Python parsing.
  Moved to `omitted.patch` (informational only, never applied).
- **`test_dis.py` (+22/-30)** — adjusts existing disassembly tests for
  the new opcode numbering. No new test methods. Nothing to score.

The 49 test_except_star.py methods are the canonical PEP 654 system-
test suite and amply cover the new feature surface; the out-of-scope
exclusions trade marginal coverage for ratio cleanliness and avoid
unit-flavored / flaky tests.

---

## 4. Validation status — passed 2026-05-21

| Suite | Pre-state | Post-state | Mutants | Coverage |
| --- | --- | --- | --- | --- |
| `orig` | F2P 0/50 (50 ERROR), P2P 59/59 PASS | F2P 50/50 PASS, P2P 59/59 PASS, `resolved=true` | baseline only | 79.6% union C/H line coverage |
| `aug` | F2P 0/10 (10 ERROR), P2P 4/4 PASS | F2P 10/10 PASS, P2P 4/4 PASS, `resolved=true` | sidecar F2P kills all 20 mutants | 88.1% union C/H line coverage |
| `union` | F2P 0/60 (60 ERROR), P2P 63/63 PASS | F2P 60/60 PASS, P2P 63/63 PASS, `resolved=true` | all 20 mutants killed; all P2P clean | 88.1% union C/H line coverage |

Initial draft had P2P=60 but the first validation surfaced one false-
positive: `test_ast.AST_Tests.test_ast_validation` iterates the same
module-level `exec_tests` list that `test_snippets` does, and the PR
added an `except*` snippet to that list — so `test_ast_validation`
ERRORs at pre-state when `ast.parse` hits the new snippet. Removed
before the green run; documented in
`spec.json.out_of_scope_surfaces`.

To reproduce:

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-29581:1 .
./validate.sh   # writes validation_out/{orig,aug,union}/ and asserts invariants
docker build -t lolbench/cpython-pr-29581-coverage:1 -f coverage/Dockerfile .
LOLBENCH_SUITE=union docker run --rm --network=none -v "$PWD/coverage_out:/out" --memory 7g --cpus 4 lolbench/cpython-pr-29581-coverage:1
```

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17 for the running log of
build / runner traps. PEP-654 specific items:

- **`Parser/parser.c` empty in pr_files_cache**: GitHub-API patch
  truncation. Reconstructed via `git diff 850aefc2..d60457a6 --
  Parser/parser.c` on the local clone.
- **3 test files with literal except* in method bodies**: moved to
  `omitted.patch` to prevent pre-state Python-parse breakage. The
  except* coverage they provide is duplicated by test_except_star.py.
- **base_commit vs GitHub PR-base**: same pattern as PEP-617 / PEP-634.
  Use the merge parent `850aefc2…`, not the GitHub PR-base `b9310773…`.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `7g`
- Timeout: `5400` seconds
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

**79.63% / 87.64% / 88.1%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

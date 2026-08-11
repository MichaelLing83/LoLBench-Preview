# LoLBench Instance: CPython PR-22917 (PEP 634)

> **Requirement**: [PEP 634](https://peps.python.org/pep-0634/) — "Structural Pattern Matching: Specification"
> **Implementing PR**: [python/cpython#22917](https://github.com/python/cpython/pull/22917)
> **base_commit**: `cc02b4f2e810ab524d845daa18bc94df5b092dd8`  (2019-09, parent of merge commit `145bf269`)
> **Language mix**: C (grammar/parser/AST/compiler/ceval/objects) + Python (stdlib ast, dataclasses, collections, opcode, keyword)

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — P2P refreshed 2026-06-15.** Original and union suites
> pass the expanded P2P invariant. The union suite has 293 F2P and 54
> P2P selectors. Historical mutant validation kills all 20 committed
> PEP-634 mutants, and refreshed union coverage remains 91.9% on the
> measured hand-written C surface.

> **Base-commit note.** GitHub reports the PR base as
> `409de6ccc9507f66ae0eb1f5f253e7a7c7a18f82` for this row (the
> PR-creation-time tip, 2020-09-12). The PR was rebased before merge —
> the parent of merge commit `145bf269df3530176f6ebeab1324890ef7070bf8`
> is `cc02b4f2…`, and the patches in this bundle apply cleanly only
> against that commit. Same pattern as the PEP-617 instance. The
> override is recorded in `spec.json.base_commit_note`.

---

## TL;DR — evaluate a solution

```bash
./eval.sh path/to/your/solution.patch
```

Prints a one-line verdict and writes `eval_out/agent_report.json`.
Exit code is `0` iff the patch is **resolved** (F2P and P2P all pass).

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 285 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 8 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 293 | 54 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

The current `eval.sh` wrapper does not expose a `--suite` flag. Run the image directly when you need a non-default suite:

```bash
docker run --rm \
  --network=none \
  --memory 7g --cpus 4 \
  -e LOLBENCH_SUITE=union \
  -v $(pwd)/solution.patch:/in/solution.patch:ro \
  -v $(pwd)/out:/out \
  lolbench/cpython-pr-22917:1
```

## 1. Bundle layout

```
dockers/CPython_PEP-634_Structural-Pattern-Matching_PR-22917/
├── README.md                ← this file
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
│
├── Dockerfile               ← layer-3 eval image (lolbench/cpython-pr-22917:1)
├── spec.json                ← instance metadata + F2P/P2P + triage
├── solution.patch           ← 36 files (Grammar/python.gram, Parser/parser.c regen, ASDL, AST, compile, ceval, opcode, 10 Objects/ files for __match_args__, 6 stdlib .py files)
├── eval_tests.patch         ← 4 files (NEW test_patma.py 2878 lines + small additions to test_ast/test_collections/test_dataclasses)
├── eval_tests_aug.patch     ← sidecar augmented tests (new files only)
├── omitted.patch            ← 3 files: Doc/ + NEWS entry
├── f2p.txt                  ← 285 system tests: all 282 TestPatma.test_patma_NNN + 3 __match_args__ + 1 test_snippets
├── f2p_aug.txt              ← 8 augmented F2P selectors
├── p2p.txt                  ← 50 stable pre-existing test_grammar.py + test_ast.py methods (P2P/F2P = 0.18×)
├── p2p_aug.txt              ← 4 augmented P2P selectors
├── run_tests.sh             ← container entrypoint
├── test_augmentation/       ← augmented test sources + audit
├── coverage_out/            ← final orig / aug / union coverage reports
│
├── base/                    ← layer-2 base image (reused with the PEP-768/PEP-617 instances)
│   └── Dockerfile             lolbench/cpython-base:1
│
└── coverage/                ← curation-time gcov bundle (separate one-shot image)
    ├── Dockerfile             lolbench/cpython-pr-22917-coverage:1 (Debug + --coverage)
    ├── run_coverage.sh        applies both patches, rebuilds instrumented, runs F2P + P2P, snapshots .gcda
    └── compute_coverage.py    parses solution.patch + gcovr JSON
```

### Capabilities

PEP 634 runs entirely in-process (no `process_vm_readv`, no
cross-process attach). `eval.sh` and `validate.sh` do **not** add
`--cap-add=SYS_PTRACE`; the container runs with `--network=none` and
the default seccomp profile.

---

## 2. Building the images

```bash
# layer-2 base (already built for PEP-768/PEP-617; reused here)
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/

# layer-3 eval image
docker build -t lolbench/cpython-pr-22917:1 .

# (optional, one-time) coverage image — Debug + gcov instrumentation
docker build -t lolbench/cpython-pr-22917-coverage:1 -f coverage/Dockerfile .
```

The patches were derived from `git diff cc02b4f2…145bf269` (the merge
parent and PR-22917 merge commit), then split by file role per the
plan's §1 contract. `Parser/parser.c` (+11135 / −7806 lines, generated
parser table) had an empty patch field in `pr_files_cache` because
the GitHub API truncates very large diffs; the canonical content was
reconstructed via `git diff` on the local clone.

Reconstruction validation: solution.patch ∪ eval_tests.patch ∪
omitted.patch equals the full PR file set (43 files), all three apply
cleanly via `git apply --check` against `base_commit`, and the
post-state (`solution + eval_tests`) applies cleanly on top.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure modes

At pre-state (`base_commit + eval_tests.patch` only):

- **test_patma.py** uses `match`/`case` syntax at base_commit, but the
  old parser (`cc02b4f2`, pre-3.10) does not recognise those soft
  keywords as statement-level constructs → `SyntaxError` during
  module load → all 282 selected `TestPatma.test_patma_NNN` methods
  ERROR.
- **test_collections.TestNamedTuple.test_match_args** references
  `Point.__match_args__` on a namedtuple; the `__match_args__`
  attribute is added to namedtuple by solution.patch in
  `Lib/collections/__init__.py` → pre-state AttributeError → ERROR.
- **test_dataclasses.TestMatchArgs.test_match_args** references `instance.__match_args__`
  on a `@dataclass` instance; pre-state AttributeError → ERROR.
- **test_ast.AST_Tests.test_snippets** calls `_assertTrueorder` which
  the PR extended with `self.assertEqual(ast_node._fields,
  ast_node.__match_args__)`; AST node classes don't have
  `__match_args__` until solution.patch regenerates them via
  `Parser/asdl_c.py` → pre-state AttributeError → ERROR.

All 285 original F2P transitions are clean ERROR → PASS through the
§6.4 gate.

### 3.2 F2P (285 methods)

| # | Test | Pre-state fail mode |
| --- | --- | --- |
| 1-282 | `TestPatma.test_patma_000` through `test_patma_281` *(every method in the canonical PEP-634 test class)* | `SyntaxError` on match/case (module ImportError → 282 × ERROR) |
| 283 | `TestNamedTuple.test_match_args` *(test_collections.py)* | AttributeError on `namedtuple.__match_args__` |
| 284 | `TestMatchArgs.test_match_args` *(test_dataclasses.py)* | AttributeError on dataclass instance.__match_args__ |
| 285 | `AST_Tests.test_snippets` *(test_ast.py)* | AttributeError on `ast.AST.__match_args__` |

`TestMatchArgs.test_explicit_match_args` is intentionally **NOT** in F2P
even though it was added by the PR: its body sets `__match_args__ = ma`
explicitly as a class attribute, which survives the `@dataclass`
decorator at both pre- and post-state → no transition → invalid F2P.
Documented in `spec.json.out_of_scope_surfaces`.

#### Why all 282 TestPatma methods (revised after Codex review)

`Lib/test/test_patma.py` is a wholesale-new 2878-line file added by
the PR; its single `TestPatma` class has 282 sequentially-numbered
methods (`test_patma_000` through `test_patma_281`). Each method
exercises one specific PEP-634 case: literal patterns, capture
patterns, sequence patterns, mapping patterns, class patterns,
or-patterns, as-patterns, guards, wildcards, nested compositions,
duplicate-capture syntax errors, mapping-duplicate-key errors,
class-pattern-arity errors — every edge case the spec covers.

The earlier draft sampled every 20th method (15 of 282). The Codex
review pointed out that the sample understates correctness coverage:
a candidate implementation could pass the 15 sampled cases while
silently missing some of the 267 unselected upstream cases (the
sample is *representative*, not *exhaustive*). Since the
programmatic-runner overhead is ~50 ms per test, running all 282 adds
only ~15 s to the validation wall time — well worth the complete
coverage. F2P now lists every method.

`PerfPatma` (the second class in test_patma.py) subclasses
`TestPatma` to time it under PGO; it carries no new coverage and is
documented in `spec.json.out_of_scope_surfaces`.

### 3.3 P2P (50 methods)

All from `Lib/test/test_grammar.py` (38) and `Lib/test/test_ast.py` (12
of 52 — excluding `test_snippets` which is now F2P). Neither file is
appreciably modified by the PR (`test_ast.py` has only one `+1` line
inside the `_assertTrueorder` helper that only `test_snippets`
invokes). At post-state these tests still go through CPython's normal
`compile()` / `ast.parse` surface — the parser change keeps existing
grammar paths green, and the test bodies don't exercise the new
match/case syntax.

| Class | # | Examples |
| --- | ---: | --- |
| `test_grammar.TokenTests` | 6 | `test_backslash`, `test_ellipsis`, `test_floats`, `test_plain_integers`, `test_long_integers`, `test_string_literals` |
| `test_grammar.GrammarTests` | 32 | `test_eval_input`, `test_funcdef`, `test_lambdef`, control flow (`test_if`/`while`/`for`/`try`), declarations (`test_del_stmt`/`pass_stmt`/`return`/`raise`/`yield`/`import`/`global`/`nonlocal`), expressions (`test_atoms`/`comparison`/`shift_ops`/`multiplicative_ops`), comprehensions (`test_dictcomps`/`listcomps`/`genexps`), annotations (`test_var_annot_basics`), `test_classdef`, `test_async_await`, `test_with_statement`, `test_break_continue_loop`, etc. |
| `test_ast.AST_Tests` | 6 | `test_AST_objects`, `test_arguments`, `test_slice`, `test_from_import`, `test_base_classes`, `test_no_fields` |
| `test_ast.ASTHelpers_Test` | 5 | `test_parse`, `test_dump`, `test_literal_eval`, `test_copy_location`, `test_iter_fields` |
| `test_ast.ConstantTests` | 1 | `test_singletons` |

All 50 method names were verified to exist at `base_commit`.
Ratio P2P/F2P = 0.18× — deliberately small because the full upstream
`TestPatma` class (now in F2P) is the canonical correctness gate for
PEP 634, and P2P breadth is bounded by the relatively small
neighbourhood of grammar/AST tests that exist and stay untouched at
base_commit.

---

### 3.4 Augmented Sidecar Suites

The sidecar suite adds 8 F2P selectors in `Lib/test/test_patma_aug.py`
and 4 P2P selectors in `Lib/test/test_patma_stability_aug.py`.

F2P covers the committed mutation set through public behavior:
soft-keyword registration, namedtuple/dataclass `__match_args__`,
builtin and subclass class patterns, string exclusion from sequence
patterns, mapping extra-key behavior, duplicate class keywords,
singleton identity matching, guards, AS/capture/wildcard semantics,
irrefutable-case validation, OR binding consistency, AST validation,
and a broad compile-only sweep of documented pattern grammar forms.

P2P intentionally avoids `match` syntax so it runs at pre-state, and
pins ordinary identifier use of `match`/`case`/`_`, established
namedtuple behavior, established dataclass behavior, and ordinary
AST/compile control-flow behavior.

---

## 4. Validation status — P2P refreshed 2026-06-15

| Row | Working tree | F2P | P2P | Outcome |
| --- | --- | --- | --- | --- |
| `orig validate_pre` | `base_commit + eval_tests.patch` | 0/285 (285 ERROR) | 50/50 PASSED | matches "F2P all FAIL/ERROR + P2P all PASS" |
| `orig validate_post` | `base_commit + solution.patch + eval_tests.patch` | 285/285 PASSED | 50/50 PASSED | `resolved=true` |
| `aug validate_pre` | original + sidecar tests | 0/8 (8 ERROR) | 4/4 PASSED | matches invariant |
| `aug validate_post` | solution + original + sidecar tests | 8/8 PASSED | 4/4 PASSED | `resolved=true` |
| `union validate_pre` | original + sidecar tests | 0/293 (293 ERROR) | 54/54 PASSED | matches invariant |
| `union validate_post` | solution + original + sidecar tests | 293/293 PASSED | 54/54 PASSED | `resolved=true` |

All 20 committed mutants in the historical mutant validation for
`mutations/CPython_PEP-634_Structural-Pattern-Matching_PR-22917/`
are killed by union F2P. `run_tests.sh` includes a
per-test subprocess fallback so mutants that abort the aggregate
interpreter still get an independent P2P measurement.

Coverage reports are in `coverage_out/`. Final union coverage is
693/754 executable measured lines, or 91.9%. `Parser/parser.c` and
`Python/Python-ast.c` are generated from `Grammar/python.gram` and
`Parser/Python.asdl`; they are recorded as raw generated patch lines
but excluded from the hand-written C coverage denominator.

To reproduce:

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-22917:1 .
./validate.sh   # writes validation_out/{orig,aug,union,mutants}/ and asserts the invariant
```

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17 for the running log of
build / runner traps (CPython 3.9/3.10-era specifics, cgroup-aware
`make -j`, etc.). PEP-634 specific items:

- **`Parser/parser.c` empty in `pr_files_cache`**: the GitHub API
  truncates very large diff bodies. Reconstructed via
  `git diff cc02b4f2..145bf269 -- Parser/parser.c` on the local
  clone (15391 lines after-state).
- **NEWS path with embedded space**: `Misc/NEWS.d/next/Core and
  Builtins/2020-10-23-08-54-04.bpo-42128.SWmVEm.rst` is in
  `omitted.patch` only — its presence in solution.patch / eval_tests
  is not required. Git diff quotes such paths.
- **base_commit vs GitHub PR-base**: as noted at the top, we override
  the GitHub PR-base `409de6c` with the actual merge parent `cc02b4f2` so
  patches apply cleanly.

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

**91.4% / 76.3% / 91.9%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

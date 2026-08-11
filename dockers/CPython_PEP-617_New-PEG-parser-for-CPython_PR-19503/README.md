# LoLBench Instance: CPython PR-19503 (PEP 617)

> **Requirement**: [PEP 617](https://peps.python.org/pep-0617/) — "New PEG parser for CPython"
> **Implementing PR**: [python/cpython#19503](https://github.com/python/cpython/pull/19503)
> **base_commit**: `a81849b0315277bb3937271174aaaa5059c0b445`  (2020-03-20, parent of merge commit `c5fc1568`)
> **Language mix**: C (new parser + parser-generator output) + Python (parser-generator tooling)

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — validated 2026-06-08 (orig), refreshed 2026-06-17 (aug/union selection expansion).**
> Section 7 invariant passes end-to-end:
> pre-state F2P 0/12 (12 ERROR) + P2P 54/54 PASSED; post-state F2P 12/12
> + P2P 54/54 PASSED, `resolved=true`. Image
> `lolbench/cpython-pr-19503:1`. The 2026-06-17 refresh added 11
> selection-expansion F2P (committed `test_peg_generator` methods) to
> `f2p_aug.txt`, reduced the mutant set 38→24 (7 §6-unreachable parse-mode
> removals + 7 PEG-generator-internal mutants with no cleanly-running
> §6-eligible committed killer in this harness — see
> `augmented.mutant_set_revision`), and confirmed a full 24-mutant `union`
> sweep kills every remaining mutant with golden green (F2P 25/25, P2P 57/57).
>
> **Base-commit note.** GitHub reports the PR base as
> `4657a8a0d006c76699ba3d1d4d21a04860bb2586` for this row, but that's
> the PR-creation-time tip — the PR was rebased before merge. The
> patches in this bundle apply cleanly only against the *parent of the
> merge commit* (`a81849b0…`), which is the value we use for `base_commit`
> everywhere in the bundle. `spec.json.base_commit_note` records the
> override.

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
| `orig` | original PR-derived hidden selectors after source-symbol cleanup | 12 | 54 |
| `aug` | sidecar (2 authored) + selection-expansion (11 committed pegen) F2P | 13 | 3 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 25 | 57 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## 1. Bundle layout

```
dockers/CPython_PEP-617_New-PEG-parser-for-CPython_PR-19503/
├── README.md                ← this file
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
│
├── Dockerfile               ← layer-3 eval image (lolbench/cpython-pr-19503:1)
├── spec.json                ← instance metadata + F2P/P2P + triage
├── solution.patch           ← 60 files (Grammar + Parser/pegen + Tools/peg_generator + ...)
├── eval_tests.patch         ← 25 files (new test_peg_parser.py + test_peg_generator/ + 18 modified Lib/test/*.py)
├── omitted.patch            ← 6 files: docs + CI configs + xxl.zip binary fixture
├── f2p.txt                  ← 12 system tests: 6 retained TestCParser parser-generator behaviors + 6 pre-existing inline-gated on sys.flags.use_peg
├── p2p.txt                  ← 54 stable test_grammar.py / test_ast.py methods (P2P/F2P = 4.50×)
├── run_tests.sh             ← container entrypoint
│
├── base/                    ← layer-2 base image (reused with the PEP-768 instance)
│   └── Dockerfile             lolbench/cpython-base:1
│
└── coverage/                ← curation-time gcov bundle (separate one-shot image)
    ├── Dockerfile             lolbench/cpython-pr-19503-coverage:1 (Debug + --coverage)
    ├── run_coverage.sh        applies both patches, rebuilds instrumented, runs F2P + P2P, snapshots .gcda
    └── compute_coverage.py    parses solution.patch + gcovr JSON
```

### Capabilities

Unlike the [PEP-768 instance](../CPython_PEP-768_Safe-external-debugger-interface-for-CPython_PR-131937/),
this PR's new parser runs entirely in-process — no `process_vm_readv`,
no cross-process attach. `eval.sh` and `validate.sh` therefore do **not**
add `--cap-add=SYS_PTRACE`; the container runs with `--network=none`
and the default seccomp profile.

---

## 2. Building the images

```bash
# layer-2 base (already built for PEP-768; reused here)
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/

# layer-3 eval image
docker build -t lolbench/cpython-pr-19503:1 .

# (optional, one-time) coverage image — Debug + gcov instrumentation
docker build -t lolbench/cpython-pr-19503-coverage:1 -f coverage/Dockerfile .
```

The patches were derived from `git diff a81849b0…c5fc1568` (the merge
parent and the PR's merge commit), then split by file role per the
plan's §1 contract. Reconstruction validation: `solution.patch ∪
eval_tests.patch ∪ omitted.patch` equals the full PR file set
(91 files), and both `solution.patch` and `eval_tests.patch` apply
cleanly via `git apply --check` against `base_commit`.

---

## 3. F2P / P2P selection

### F2P (12 methods after source-symbol cleanup)

Two complementary groups remain selected:

**Group A - 6 retained TestCParser methods (parser-generator behavior)** that exercise the grammar -> C emit -> compile -> dlopen -> parse loop via local test helpers without directly naming newly added source functions/classes absent from PEP 617. Pre-state: the `pegen` Python package added by `solution.patch` is missing -> `ImportError` on load -> ERROR. Post-state: full pipeline runs -> PASS.

| Test | What it exercises |
| --- | --- |
| `TestCParser.test_lookahead` | positive lookahead `&rule` operator |
| `TestCParser.test_negative_lookahead` | negative lookahead `!rule` operator |
| `TestCParser.test_cut` | PEG cut `~` operator (commit-no-backtrack) |
| `TestCParser.test_left_recursion` | direct left-recursive grammar (e.g. `expr: expr '+' atom | atom`) |
| `TestCParser.test_advanced_left_recursive` | multi-alternative left-recursion handling |
| `TestCParser.test_pass_stmt_action` | grammar action emits a pass-statement AST node |

**Group B - 6 pre-existing methods that the PR gated inline on `sys.flags.use_peg`** (`if not sys.flags.use_peg:` inside the test body, not an `@unittest.skipIf` decorator). At pre-state `sys.flags.use_peg` does not exist, so the gating expression raises `AttributeError` mid-test -> ERROR. At post-state the flag exists and is `1` (PEG is the default; see Section 3.1); the guarded old-parser-specific assertions are skipped, but the body's unconditional assertions still run through `compile()` and exercise the new parser:

| Test file | Inline-gated method |
| --- | --- |
| `Lib/test/test_fstring.py` | `TestCase.test_ast_line_numbers_nested` |
| `Lib/test/test_positional_only_arg.py` | `test_invalid_syntax_errors`, `test_invalid_syntax_errors_async`, `test_invalid_syntax_lambda` |
| `Lib/test/test_string_literals.py` | `test_eval_str_invalid_escape`, `test_eval_bytes_invalid_escape` |

All 6 verified to exist at `base_commit` by AST walk; their bodies were confirmed by ast.unparse to contain `if not sys.flags.use_peg:` guards.

### 3.1 Parser-default direction (post-state)

`solution.patch` sets `config->use_peg = 1` in `Python/initconfig.c` and
exposes the flag via `sys.flags.use_peg`. At post-state **PEG is the
default parser**; users opt OUT via `-X oldparser` or `PYTHONOLDPARSER`.
The runner does not pass either flag, so every `compile()` / `exec` /
`ast.parse` call in the test bodies flows through the new parser.

This means **the P2P set below also acts as new-parser regression coverage**
at post-state — they're not "orthogonal neighbours" the way the
PEP-768 P2P set was. P2P passing at post-state proves the new parser
correctly handles all the grammar/AST forms exercised.

### P2P (54 methods)

All from `Lib/test/test_grammar.py` (48) and `Lib/test/test_ast.py` (6),
**neither of which is modified by the PR**. They exercise Python's
parser through the public `compile()` / `exec` / `ast.parse` /
`ast.dump` / `ast.literal_eval` surface — at post-state via the new
PEG parser (per §3.1), so they must stay green.

| Class | # | Examples |
| --- | ---: | --- |
| `test_grammar.TokenTests` | 6 | `test_backslash`, `test_ellipsis`, `test_floats`, `test_plain_integers`, `test_long_integers`, `test_string_literals` |
| `test_grammar.GrammarTests` | 42 | every major grammar form: `test_funcdef`, `test_lambdef`, `test_classdef`, `test_atoms`, control flow (`test_if`, `test_while`, `test_for`, `test_try`, `test_break_*`, `test_continue_*`, `test_return`, `test_raise`, `test_yield*`, `test_with_statement`, `test_async_*`), declarations (`test_del_stmt`, `test_pass_stmt`, `test_import`, `test_global`, `test_nonlocal`), expressions (`test_atoms`, `test_comparison`, `test_*_ops`, `test_paren_evaluation`, `test_if_else_expr`, `test_dictcomps`, `test_listcomps`, `test_genexps`, `test_comprehension_specials`), annotations (`test_var_annot_*`) |
| `test_ast.AST_Tests` | 3 | `test_AST_objects`, `test_arguments`, `test_snippets` |
| `test_ast.ASTHelpers_Test` | 3 | `test_parse`, `test_dump`, `test_literal_eval` |

All 54 method names were AST-walk verified to exist in the cloned
source tree at `base_commit` before validation. Ratio P2P/F2P = 4.50x.

### Augmented sidecar suite

The augmented suite is opt-in through `LOLBENCH_SUITE=aug|union`. It has
13 F2P selectors (2 authored + 11 selection-expansion) and 3 P2P.

**Authored sidecar F2P (2)** — `Lib/test/test_peg_aug.py`:

- A single wrapper around CPython syntax/compile/AST/unparse regression
  modules, gated on the new parser extension, to cover broad public
  parser behavior and invalid-syntax handling under PEG.
- First-set analysis for predicate and repeat grammar forms through the
  parser-generator support code (kills the two `first_sets` mutants).

**Selection-expansion F2P (11)** — *no authoring*; these select
pre-existing committed `test_peg_generator` methods that already ship in
`eval_tests.patch` at `base_commit` (so `eval_tests_aug.patch` is
unchanged). They are §6-eligible by committed-original-suite precedent:
the same `pegen` / generated-parser surface the baseline `f2p.txt`
`TestCParser` selectors and the committed first-sets aug test already use.
The §5.5 authored-opacity gate targets newly *authored* aug tests, not
pre-existing committed tests. They exist to kill the generator-family
mutants (c_generator / python_generator / metagrammar / parser_generator
/ python_parser) that the original 12 F2P left surviving:

| Selector | Kills |
| --- | --- |
| `test_c_parser.TestCParser.test_gather` | C-gen gather + repeat1 |
| `test_c_parser.TestCParser.test_gather_action_ast` | C-gen gather (AST/order) |
| `test_c_parser.TestCParser.test_mutually_left_recursive` | C-gen left-recursion memoization |
| `test_c_parser.TestCParser.test_nasty_mutually_left_recursive` | C-gen hidden left-recursion |
| `test_pegen.TestPegen.test_optional_operator` | py-gen optional + metagrammar `?` |
| `test_pegen.TestPegen.test_alt_optional_operator` | py-gen bracketed optional |
| `test_pegen.TestPegen.test_repeat_0_simple` | py-gen repeat0 + metagrammar `*` + parser_gen loop0 |
| `test_pegen.TestPegen.test_repeat_1_simple` | py-gen repeat1 |
| `test_pegen.TestPegen.test_repeat_with_sep_simple` | py-gen/metagrammar/parser_gen gather |
| `test_pegen.TestPegen.test_lookahead` | py-gen + py-parser positive/negative lookahead |
| `test_pegen.TestPegen.test_left_recursive` | py-parser memoized-hit advances |

`test_pegen.TestPegen.test_cut` was deliberately *not* selected: its body
calls `parse_string(..., verbose=True)`, whose generated-parser trace
prints to stdout and corrupts the in-process runner's JSON. The
`python_generator` cut behavior is otherwise covered (the C cut is pinned
by the original `TestCParser.test_cut`).

Added P2P: 3 methods in `Lib/test/test_peg_stability_aug.py`, covering
unchanged public `compile()`, `eval()`, `exec()`, `codeop.compile_command`,
`ast.parse`, function annotations, and positional-only argument behavior.

Augmented validation (golden, 2026-06-17):

| Suite | Pre-state | Post-state |
| --- | --- | --- |
| `aug` | F2P 0/13 PASSED (ERROR on missing `_peg_parser` / `pegen`); P2P 3/3 PASSED | F2P 13/13 PASSED; P2P 3/3 PASSED |
| `union` | F2P 0/25 PASSED; P2P 57/57 PASSED | F2P 25/25 PASSED; P2P 57/57 PASSED |

### Mutant set (31 after §6-unreachable removal)

The mutant set was reduced from 37 to **31**. Seven parse-mode mutants
(`mutant_001`, `006`, `007`, `008`, `010`, `038`, `039`) were removed as
**§6-unreachable**: they mutate the mode / encoding-cookie / default-start
behavior of the test-facing `_peg_parser` extension module
(`Modules/_peg_parser.c`, `Tools/peg_generator/peg_extension/peg_extension.c`),
which is observable only via `_peg_parser.parse_string` / `parse_file` —
PR-added symbols whose mode semantics are absent from the requirement doc
and excluded by this bundle's own triage policy. Public
`compile()` / `eval()` / `exec()` / `ast.parse()` route through
`PyPegen_ASTFromStringObject` with the caller-supplied start mode and never
reach the mutated lines, so no §6-compliant committed test can kill them.
They were deleted from `mutations/` and from `spec.json.augmented`.

A full `union` mutant sweep (golden + every mutant under
`LOLBENCH_SUITE=union`, mounting each mutant's `solution.patch`) confirms
golden is green (F2P 25/25, P2P 57/57). The §6-clean `test_peg_generator`
selection expansion raised union kills from 12 to 24; the 7 mutants that no
cleanly-running §6-eligible committed test could distinguish in this harness
(c_generator m005/m012/m013/m027 — full-codegen test errors on golden;
python cut m018 — only test prints a verbose trace that corrupts the results
JSON; loop0/repeat0 m029/m034 — no committed test parses an empty repetition)
were removed alongside the 7 parse-mode mutants, so **all 24 remaining mutants
are killed** (`resolved=false`). See `augmented.mutant_set_revision`.

Coverage gate: `coverage_out/coverage_report_union.json` reports 79.4%
source-bearing gcov C line coverage (7,927 / 9,989, complete). The
coverage denominator excludes gcov entries mapped to blank, comment,
label, and brace-only source lines; this keeps generated C trivia out of
the LoLBench line target while preserving all statement-bearing C lines.

### Out-of-scope surfaces

- `test.test_peg_generator.test_pegen.TestPegen` and
  `test.test_peg_generator.test_first_sets.TestFirstSets`: these remain
  out of the **original** `f2p.txt` (which keeps source-symbol cleanup
  strict). A targeted subset of TestPegen methods is, however, selected
  into the **augmented** suite (`f2p_aug.txt`) by committed-original-suite
  precedent to kill the generator-family mutants — see "Selection-expansion
  F2P" above. The unselected remainder (e.g. grammar-error/visualizer
  diagnostics, the verbose `test_cut`, and the `TestGrammarVisitor` class,
  which is not a `unittest.TestCase` and therefore not loadable as a single
  selector) is left out: it adds no orthogonal mutant-kill or system-level
  coverage.
- `test.test_peg_parser.ASTGenerationTest.*` parser-equivalence methods
  and `TestCParser.test_c_parser` / `TestCParser.test_if_stmt_action`:
  excluded from the selected F2P set after source-symbol cleanup because
  their selected bodies directly invoke `parse_string` or PR-added
  `_PyPegen_*` helper names that are absent from the requirement doc.
- `test.test_peg_parser.ASTGenerationTest.test_correct_but_known_to_fail_ast_generation_on_source_files`:
  decorated `@unittest.skipIf(sys.flags.use_peg, "This tests nothing for
  now, since compile uses pegen as well")`. Since `solution.patch` makes
  PEG default at post-state, this test SKIPs, and the no-skipped rule
  forbids SKIPPED as F2P PASS.

---

## 4. Validation status - passed 2026-06-08

| Row | Working tree | F2P | P2P | Outcome |
| --- | --- | --- | --- | --- |
| `validate_pre/orig` | `base_commit + eval_tests.patch` | 0/12 (12 ERROR - `pegen` / `sys.flags.use_peg` absent) | 54/54 PASSED | matches "F2P all FAIL/ERROR + P2P all PASS" |
| `validate_post/orig` | `base_commit + solution.patch + eval_tests.patch` | 12/12 PASSED | 54/54 PASSED | `resolved=true` |
| `validate_pre/aug` | `base_commit + eval_tests.patch + eval_tests_aug.patch` | 0/13 (ERROR - `_peg_parser` / `pegen` absent) | 3/3 PASSED | matches "F2P all FAIL/ERROR + P2P all PASS" |
| `validate_post/aug` | `base_commit + solution.patch + eval_tests.patch + eval_tests_aug.patch` | 13/13 PASSED | 3/3 PASSED | `resolved=true` |
| `validate_pre/union` | original plus augmented selectors | 0/25 ERROR | 57/57 PASSED | matches "F2P all FAIL/ERROR + P2P all PASS" |
| `validate_post/union` | original plus augmented selectors | 25/25 PASSED | 57/57 PASSED | `resolved=true` (2026-06-17) |

All transitions clean — no SKIPPED, no unexpected PASS at pre-state,
no failure at post-state.

To reproduce:

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-19503:1 .
./validate.sh   # writes validation_out/{pre,post}/ and asserts the invariant
```

`spec.json.validated_at` records the date and the per-row counts.

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17 for the running log of
build / runner traps. The PEP-617 build is older (CPython 3.9.0a5,
2020-03) and uses the same Ubuntu 22.04 base as the PEP-768 instance.
The only new wrinkles vs. PEP-768 are:

- **Path with embedded space**: the NEWS entry lives under
  `Misc/NEWS.d/next/Core and Builtins/…rst`. `git diff` quotes
  such paths in the `diff --git "a/…" "b/…"` line; our split
  script handles the quoting in `quote_if_needed()`.
- **Binary fixture `xxl.zip`**: the pr_files_cache patch field is
  empty for this file (binary content). We list it in
  `omitted.patch` with a recorded reason rather than attempt to
  reconstruct from text. It's referenced only by
  `Tools/peg_generator/scripts/test_pypi_packages.py`, a benchmark
  utility not in F2P/P2P.
- **base_commit vs GitHub PR-base**: as noted at the top of this
  README, we override the GitHub PR-base `4657a8a0` with the actual
  merge parent `a81849b0` so patches apply cleanly.

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

**74.45% / 79.36% / 79.36%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

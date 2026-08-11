# LoLBench Instance: cpython PR-31018 (PEP 646 Variadic Generics)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `CPython_PEP-646_Variadic-Generics_PR-31018` |
| Repository / project | `python/cpython` |
| Requirement | https://peps.python.org/pep-0646/ |
| Implementing PR | https://github.com/python/cpython/pull/31018 |
| `base_commit` | `26cca8067bf5306e372c0e90036d832c5021fd90` |
| Language | python |
| Test framework | not recorded |
| Test level | public-api |
| Eval image | `lolbench/cpython-pr-31018:1` |
| Validation | validated at `2026-06-15T01:40:15Z` |

## Quick eval

```bash
./eval.sh path/to/solution.patch
```

The wrapper mounts the patch read-only at `/in/solution.patch`, runs the eval image with `--network=none`, writes `agent_report.json` and `run.log` under `eval_out/` by default, and exits 0 only when the patch is resolved.

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 6 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 3 | 3 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 9 | 53 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/cpython-pr-31018:1 .
docker build -t lolbench/cpython-pr-31018-coverage:1 -f coverage/Dockerfile .
```

The eval image is for repeated correctness runs. The coverage image, when present, is a one-shot curation image and is not needed for ordinary evaluation.

## Bundle file map

| Path | Purpose |
| --- | --- |
| `README.md` | bundle documentation |
| `eval.sh` | evaluator-facing wrapper for scoring a candidate solution.patch |
| `validate.sh` | grader-side pre/post invariant check |
| `Dockerfile` | correctness eval image recipe |
| `spec.json` | instance metadata, selectors, hashes, validation metadata, and triage |
| `solution.patch` | reference implementation patch used only by validation |
| `eval_tests.patch` | hidden original test patch applied by the runner |
| `eval_tests_aug.patch` | hidden augmented sidecar test patch |
| `omitted.patch` | PR hunks intentionally excluded from eval |
| `f2p.txt` | original fail-to-pass selectors |
| `p2p.txt` | original pass-to-pass selectors |
| `f2p_aug.txt` | augmented fail-to-pass selectors |
| `p2p_aug.txt` | augmented pass-to-pass selectors |
| `run_tests.sh` | container entrypoint for eval and validation modes |
| `base/` | optional project base image recipe or dependency cache recipe |
| `coverage/` | optional instrumented coverage image recipe |
| `coverage_out/` | committed or local coverage reports |
| `test_augmentation/` | source files and audit notes for augmented tests |
| `validation_out/` | local validation output, when retained |

## Selector and validation summary

| Suite | F2P | P2P |
| --- | ---: | ---: |
| `orig` | 6 | 50 |
| `aug` | 3 | 3 |
| `union` | 9 | 53 |

Curator note:

> 6 F2P from modified test methods exercising PEP-646's `*Ts` unpacking syntax in subscripts and annotations. Pre-state rejects `a[*a]` / `tuple[*Ts]` / `def f(*args: *Ts):` syntax at exec()/ast.parse() time; post-state parses and round-trips them. 50 original P2P selectors come from pre-existing CPython tests outside the PEP-646 requirement behavior: 9 TokenTests, 31 GrammarTests, 2 AST_Tests, 4 IntTestCases, 2 GeneralFloatCases, and 2 string.ModuleTest selectors. The 32 selectors added on 2026-06-15 were confirmed in the base image and appended to `p2p.txt`, not `p2p_aug.txt`. Ratio P2P/F2P = 8.33×.

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 85.7%, 12/14, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. `orig`, `aug`, and `union` reports may coexist; the union report is the preferred audit signal when augmented tests are shipped.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `7g`
- Timeout: `not recorded` seconds
- Eval-time network: disabled with `--network=none`.

If `platform` is `linux/arm64` or the Dockerfiles hard-code an architecture-specific toolchain, run or rebuild on a compatible host or document a multi-arch replacement before publishing the bundle.

## Troubleshooting

- `image not found`: build the eval image first, or use the image tag shown in this README.
- `patch_apply_failure`: regenerate the candidate patch against the exact `base_commit` above.
- `eval_patch_apply_failure` or `eval_aug_patch_apply_failure`: the hidden test patch no longer applies cleanly on top of the candidate; treat this as bundle-maintainer work.
- `build_failure`: inspect `eval_out/run.log`; dependency downloads should not occur at eval time.
- no `agent_report.json`: inspect the last lines of `eval_out/run.log` and confirm Docker had the memory/CPU budget recorded above.

## Previous curation notes

The notes below were present before README normalization and are retained for instance-specific details.

# LoLBench Instance: CPython PR-31018 (PEP 646: Variadic Generics)

> **Requirement**: [PEP 646](https://peps.python.org/pep-0646/) — "Variadic Generics"
> **Implementing PR**: [python/cpython#31018](https://github.com/python/cpython/pull/31018)
> **base_commit**: `26cca8067bf5306e372c0e90036d832c5021fd90` (parent of squash-merge `e8e737bc`)
> **Language mix**: 3 C source files (parser.c, ast_unparse.c, compile.c) + 2 Python files (ast.py, typing.py) + Grammar/python.gram (regenerates parser.c)

> **Status — refreshed and validated.** `spec.json.validated_at` is `2026-06-15T01:40:15Z`.

## 1. Bundle layout

```
dockers/CPython_PEP-646_Variadic-Generics_PR-31018/
├── README.md
├── eval.sh
├── validate.sh
├── Dockerfile               ← lolbench/cpython-pr-31018:1
├── spec.json
├── solution.patch           ← 6 files (3 C + 2 Python + 1 grammar)
├── eval_tests.patch         ← 5 modified test files (incl. NEW test_pep646_syntax.py doctest)
├── omitted.patch            ← 1 NEWS entry
├── f2p.txt                  ← 6 behavioral methods
├── p2p.txt                  ← 50 stable methods (P2P/F2P = 8.33×)
├── run_tests.sh
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← hybrid coverage.py + gcov (2 Py + 3 C)
```

## 2. F2P / P2P

### 3.2 F2P (6 methods)

PEP-646 ships most of its test surface as **doctests** in
`test_pep646_syntax.py`. `unittest.TestLoader.loadTestsFromName` can't
directly invoke doctests, so the F2P set is necessarily narrow: the 6
unittest-style methods in modified test files that exercise the new
`*Ts` unpacking:

| Selector | Source |
| --- | --- |
| `test_future.AnnotationsFutureTestCase.test_annotations` | tests `tuple[*types]` and `slice[*Ts,]` annotation roundtrip |
| `test_future.AnnotationsFutureTestCase.test_get_type_hints_on_func_with_variadic_arg` | NEW method, get_type_hints on `def f(*args: *Ts):` |
| `test_unparse.UnparseTestCase.test_slices` | ast.parse + ast.unparse roundtrip on `a[*a]` |
| `test_unparse.CosmeticTestCase.test_slices` | src→ast→src roundtrip cosmetic check on `a[*a,]` |
| `test_ast.AST_Tests.test_snippets` | ast snippet coverage for new PEP-646 starred syntax |
| `test_ast.AST_Tests.test_ast_validation` | AST validation coverage for the new starred syntax path |

### 3.3 P2P (50 methods)

From pre-existing selectors in CPython's test_grammar, test_int, test_float, test_string, and test_ast coverage. The 32 selectors added on 2026-06-15 were confirmed against the base image and appended to `p2p.txt`; `p2p_aug.txt` remains reserved for synthesized augmented P2P.

### 3.4 Out-of-scope

`test_pep646_syntax.py` (the canonical PEP-646 doctest file) is in
eval_tests.patch for fidelity but cannot be invoked through the runner
— it has no TestCase class or `load_tests` hook. Direct original F2P
coverage on this PR therefore reflects the 6 unittest-loadable methods;
the augmented sidecar adds wrapper selectors for extra syntax coverage.

## 4. Validation status

`validated_at` is `2026-06-15T01:40:15Z`. The pre/post invariant was
refreshed after expanding original P2P to 50 selectors.

Observed:
- orig pre-state: 6 F2P ERROR; 50 P2P PASS.
- orig post-state: 6 F2P + 50 P2P PASS, resolved=true.
- union pre-state: 9 F2P ERROR; 53 P2P PASS.
- union post-state: 9 F2P + 53 P2P PASS, resolved=true.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**85.7% / 57.1% / 85.7%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

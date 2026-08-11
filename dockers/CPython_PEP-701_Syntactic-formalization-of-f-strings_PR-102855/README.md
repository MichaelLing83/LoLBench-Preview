# LoLBench Instance: cpython PR-102855 (PEP 701 Syntactic formalization of f strings)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `CPython_PEP-701_Syntactic-formalization-of-f-strings_PR-102855` |
| Repository / project | `python/cpython` |
| Requirement | https://peps.python.org/pep-0701/ |
| Implementing PR | https://github.com/python/cpython/pull/102855 |
| `base_commit` | `a6b07b5a345f7f54ee9f6d75e81d2fb55971b35c` |
| Language | python |
| Test framework | not recorded |
| Test level | public-api |
| Eval image | `lolbench/cpython-pr-102855:1` |
| Validation | validated at `2026-05-22T03:18:51Z` |

## Quick eval

```bash
./eval.sh path/to/solution.patch
```

The wrapper mounts the patch read-only at `/in/solution.patch`, runs the eval image with `--network=none`, writes `agent_report.json` and `run.log` under `eval_out/` by default, and exits 0 only when the patch is resolved.

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 75 | 192 |
| `aug` | mutation/coverage-driven sidecar selectors only | 8 | 3 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 83 | 195 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/cpython-pr-102855:1 .
docker build -t lolbench/cpython-pr-102855-coverage:1 -f coverage/Dockerfile .
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

## Selector and validation summary

| Suite | F2P | P2P |
| --- | ---: | ---: |
| `orig` | 75 | 192 |
| `aug` | 8 | 3 |
| `union` | 83 | 195 |

Curator note:

> 75 F2P = ALL test_fstring.TestCase methods. test_fstring.py has module-level PEP-701 syntax (post-PR file in eval_tests.patch) → file fails to parse at pre-state → all 75 ERROR at unittest module-load uniformly. Post-state: file imports fine, all pass. 18 P2P unchanged. Ratio P2P/F2P = 0.24× (below 2× because F2P expanded to ALL test_fstring methods to maximize coverage; this is a unique signal where every F2P shares the same pre-state failure mode, so granularity isn't preserved). Codex round 2 confirmed public-surface compliance: no internal symbols referenced.

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 84.2%, 443/526, coverage_complete=true

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

# LoLBench Instance: CPython PR-102855 (PEP 701: f-string PEG)

> **Requirement**: [PEP 701](https://peps.python.org/pep-0701/) — "Syntactic formalization of f-strings"
> **Implementing PR**: [python/cpython#102855](https://github.com/python/cpython/pull/102855)
> **base_commit**: `a6b07b5a345f7f54ee9f6d75e81d2fb55971b35c` (parent of squash-merge `1ef61cf7`)

PEP 701 makes f-string parsing first-class PEG (removes the ad-hoc
f-string lexer/parser, replaces with grammar productions). Touches
Grammar/Tokens, Grammar/python.gram, Parser/* (parser, pegen, tokenizer,
string_parser, action_helpers), Python/Python-tokenize.c.

## F2P (8) — all new `test_fstring.TestCase` methods

| Method | Exercises |
| --- | --- |
| test_backslashes_in_expression_part | `f"{x\\n}"` — backslashes inside braces |
| test_fstring_backslash_before_double_bracket | `f"\\{{x}}"` |
| test_fstring_backslash_prefix_raw | rf"..." combinations |
| test_fstring_format_spec_greedy_matching | `f"{x:>{w}}"` |
| test_fstring_nested_too_deeply | nesting depth limit |
| test_invalid_backslashes_inside_fstring_context | error paths |
| test_roundtrip_raw_quotes | raw + quotes interaction |
| test_valid_prefixes | new prefix combinations |

All exec/compile PEP-701 f-string source. Pre-state: tokenizer/parser
rejects → SyntaxError.

## P2P (18) — 4 untouched files: test_grammar (11), test_int (3), test_float (2), test_string (2). Ratio 2.25×.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**83.8% / 79.1% / 84.2%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

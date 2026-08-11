# LoLBench Instance: cpython PR-119891 (PEP 649 Deferred Evaluation Of Annotations Using Descriptors)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `CPython_PEP-649_Deferred-Evaluation-Of-Annotations-Using-Descriptors_PR-119891` |
| Repository / project | `python/cpython` |
| Requirement | https://peps.python.org/pep-0649/ |
| Implementing PR | https://github.com/python/cpython/pull/119891 |
| `base_commit` | `64e221d7ada8f6c20189035c7e81503f4c914f04` |
| Language | python |
| Test framework | not recorded |
| Test level | public-api |
| Eval image | `lolbench/cpython-pr-119891:1` |
| Validation | validated at `2026-05-25T00:04:12Z` |

## Quick eval

```bash
./eval.sh path/to/solution.patch
```

The wrapper mounts the patch read-only at `/in/solution.patch`, runs the eval image with `--network=none`, writes `agent_report.json` and `run.log` under `eval_out/` by default, and exits 0 only when the patch is resolved.

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 42 | 78 |
| `aug` | mutation/coverage-driven sidecar selectors only | 18 | 2 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 60 | 80 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/cpython-pr-119891:1 .
docker build -t lolbench/cpython-pr-119891-coverage:1 -f coverage/Dockerfile .
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
| `orig` | 42 | 78 |
| `aug` | 18 | 2 |
| `union` | 60 | 80 |

Curator note:

> 33 F2P all from NEW test_annotationlib.py. Pre-state: Lib/annotationlib.py doesn't exist → ModuleNotFoundError at test load → all 33 ERROR. 62 P2P from 8 untouched test files. Ratio P2P/F2P = 1.88×.

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 92.6%, 424/458, coverage_complete=true

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

# LoLBench Instance: CPython PR-119891 (PEP 649)

> PEP-649 Deferred Evaluation Of Annotations Using Descriptors.
> base: 64e221d7  merge: 7b7b90d1

F2P (42): 33 test_annotationlib.* (NEW) + 9 new methods in test_dataclasses / test_functools / test_typing exercising deferred annotations. Pre-state: ModuleNotFoundError or AttributeError.
P2P (78): 9 untouched files (test_int, test_float, test_string, test_list, test_dict, test_calendar, test_set, plus extras). Ratio 1.86×.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**58.3% / 76.4% / 92.6%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

# LoLBench Instance: fastapi PR-4871 (PEP 593 Flexible function and variable annotations)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871` |
| Repository / project | `fastapi/fastapi` |
| Requirement | https://peps.python.org/pep-0593/ |
| Implementing PR | https://github.com/fastapi/fastapi/pull/4871 |
| `base_commit` | `ef176c663195489b44030bfe1fb94a317762c8d5` |
| Language | python |
| Test framework | not recorded |
| Test level | system |
| Eval image | `lolbench/fastapi-pr-4871:1` |
| Validation | validated at `2026-06-15T00:00:00Z` |

## Quick eval

```bash
./eval.sh path/to/solution.patch
```

The wrapper mounts the patch read-only at `/in/solution.patch`, runs the eval image with `--network=none`, writes `agent_report.json` and `run.log` under `eval_out/` by default, and exits 0 only when the patch is resolved.

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 9 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 2 | 1 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 11 | 51 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/fastapi-pr-4871:1 .
docker build -t lolbench/fastapi-pr-4871-coverage:1 -f coverage/Dockerfile .
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
| `orig` | 9 | 50 |
| `aug` | 2 | 1 |
| `union` | 11 | 51 |

Curator note:

> 9 F2P: 7 are TestClient-driven HTTP integration tests (test_annotated.test_get + 6 test_tutorial/test_annotated/test_tutorial*.test_get) exercising Annotated[T, Query()] / Annotated[T, Depends()] dependency injection. 2 (test_ambiguous_params) use pytest.raises against public FastAPI route decoration to verify the new restrictions on mixing Annotated metadata with defaults. Pre-state mechanism: solution.patch adds Annotated handling in fastapi/dependencies/utils.py + params.py; without it, decorators don't raise the expected error and HTTP-level tests get wrong parameter resolution.

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 96.7%, 89/92, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. `orig`, `aug`, and `union` reports may coexist; the union report is the preferred audit signal when augmented tests are shipped.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `2`, memory `4g`
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

# LoLBench instance: FastAPI PR-4871 — PEP 593 (Annotated for dependency injection)

- **PEP:** [PEP 593](https://peps.python.org/pep-0593/) — Flexible function and variable annotations
- **PR:** https://github.com/fastapi/fastapi/pull/4871
- **base_commit:** ef176c663195489b44030bfe1fb94a317762c8d5 (squash-parent; GitHub PR-base 4bb8ac21 overridden)
- **merge_commit:** 375513f11494bc3499050ad2a0d378fb6e37ca98

## Patch breakdown

| Patch | Files | Purpose |
|-------|------:|---------|
| solution.patch | 4 | `fastapi/dependencies/utils.py`, `fastapi/param_functions.py`, `fastapi/params.py`, `fastapi/utils.py` — add support for `Annotated[T, Query()]` / `Annotated[T, Depends()]` / etc. in dependency resolution |
| eval_tests.patch | 20 | NEW `tests/test_annotated.py` (parametrized TestClient test), NEW `tests/test_ambiguous_params.py`, NEW `tests/test_tutorial/test_annotated/test_tutorial001*.py` ×6, NEW `docs_src/annotated/tutorial001*.py` ×6 (fixture apps), edits to `tests/main.py`, `tests/test_application.py`, `tests/test_params_repr.py`, `tests/test_path.py` |
| omitted.patch | 0 | (None) |

## F2P / P2P

F2P (9): all from NEW test files exercising Annotated[T, Query()] / Annotated[T, Depends()] via FastAPI TestClient HTTP integration. Pre-state: FastAPI's dependency resolver doesn't recognize Query/Depends inside Annotated → wrong parameter handling (422 or unexpected default behavior).

P2P (50): untouched original upstream tests from `tests/test_additional_*`, dependency, parameter, query, request-body, and OpenAPI coverage. The 2026-06-15 expansion added 25 pre-existing selectors to `p2p.txt`; `p2p_aug.txt` remains the synthesized sidecar lane only.

## Build

```bash
docker build -t lolbench/fastapi-base-py310:1 -f base/Dockerfile base/
docker build -t lolbench/fastapi-pr-4871:1 .
```

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**96.7% / 56.5% / 96.7%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

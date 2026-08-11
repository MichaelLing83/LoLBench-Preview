# LoLBench Instance: Ruff PR-9599 (Issue 8368 Allow override of configuration options via the CLI)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599` |
| Repository / project | `astral-sh/ruff` |
| Requirement | https://github.com/astral-sh/ruff/issues/8368 |
| Implementing PR | https://github.com/astral-sh/ruff/pull/9599 |
| `base_commit` | `b21ba71ef4b897cbb9e3c402f081887b650b6448` |
| Language | Rust |
| Test framework | cargo-libtest |
| Test level | system |
| Eval image | `lolbench/ruff-pr-9599:1` |
| Validation | expanded P2P validated at `2026-06-15` |

## Quick eval

```bash
./eval.sh path/to/solution.patch
```

The wrapper mounts the patch read-only at `/in/solution.patch`, runs the eval image with `--network=none`, writes `agent_report.json` and `run.log` under `eval_out/` by default, and exits 0 only when the patch is resolved.

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 17 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 2 | 1 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 19 | 51 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/ruff-pr-9599:1 .
docker build -t lolbench/ruff-pr-9599-coverage:1 -f coverage/Dockerfile .
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
| `p2p.txt` | original pass-to-pass selectors, expanded with pre-existing upstream integration tests |
| `f2p_aug.txt` | augmented fail-to-pass selectors |
| `p2p_aug.txt` | synthesized augmented pass-to-pass selector |
| `run_tests.sh` | container entrypoint for eval and validation modes |
| `coverage/` | optional instrumented coverage image recipe |
| `coverage_out/` | committed or local coverage reports |
| `test_augmentation/` | source files and audit notes for augmented tests |
| `validation_out/` | local validation output, when retained |

## Selector and validation summary

| Suite | F2P | P2P |
| --- | ---: | ---: |
| `orig` | 17 | 50 |
| `aug` | 2 | 1 |
| `union` | 19 | 51 |

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 88.1%, 290/329, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. `orig`, `aug`, and `union` reports may coexist; the union report is the preferred audit signal when augmented tests are shipped.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `8g`
- Timeout: `3600` seconds
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

# LoLBench instance: Ruff PR-9599 (Issue-8368)

Lets users override arbitrary Ruff configuration options inline via the
CLI — both `--config <path/to/file>` (existing TOML-file syntax) and
the new `--config 'key=value'` inline overrides. Adds collision
detection (`--isolated`, `--no-cache`, multiple `--config` paths),
deprecated-option migration, and per-rule extend-select support.

## Test selectors

### F2P — 17 integration tests in `crates/ruff/tests/{format,lint}.rs`

| # | Selector |
|---|----------|
| 1 | `format::config_override_via_cli` |
| 2 | `format::config_doubly_overridden_via_cli` |
| 3 | `format::nonexistent_config_file` |
| 4 | `format::config_override_rejected_if_invalid_toml` |
| 5 | `format::too_many_config_files` |
| 6 | `format::config_file_and_isolated` |
| 7 | `lint::config_override_via_cli` |
| 8 | `lint::config_doubly_overridden_via_cli` |
| 9 | `lint::nonexistent_config_file` |
| 10 | `lint::config_override_rejected_if_invalid_toml` |
| 11 | `lint::too_many_config_files` |
| 12 | `lint::config_file_and_isolated` |
| 13 | `lint::valid_toml_but_nonexistent_option_provided_via_config_argument` |
| 14 | `lint::each_toml_option_requires_a_new_flag_1` |
| 15 | `lint::each_toml_option_requires_a_new_flag_2` |
| 16 | `lint::complex_config_setting_overridden_via_cli` |
| 17 | `lint::deprecated_config_option_overridden_via_cli` |

### P2P — 50 (strict §7, untouched test binaries)

| # | Selector |
|---|----------|
| 1 | `integration_test::stdin_success` |
| 2 | `show_settings::display_default_settings` |
| 3 | `resolve_files::check_project_include_defaults` |
| ... | 47 additional pre-existing `integration_test::*` selectors listed in `p2p.txt` |

`cargo test --test <file>` only compiles that binary's deps, so the
pre-state `format`/`lint` compile failure (the §7 F2P signal) does
not affect the P2P binaries.

The expanded original P2P set contains only pre-existing Ruff integration tests from the base checkout. These selectors are recorded in `p2p.txt`; the synthesized augmented P2P selector remains only in `p2p_aug.txt`.

## Toolchain

Rust 1.76 (per `rust-toolchain.toml` at base), edition 2021,
ruff workspace cargo build.

Base commit `b21ba71` (parent of squash-merge `8ec5627`).

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**86.9% / 39.8% / 88.1%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

# LoLBench Instance: Apache Flink PR-26001 (FLIP 501 Support Window Extension in DataStream V2 API)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `Apache-Flink_FLIP-501-Support-Window-Extension-in-DataStream-V2-API_PR-26001` |
| Repository / project | `apache/flink` |
| Requirement | https://cwiki.apache.org/confluence/display/FLINK/FLIP-501 |
| Implementing PR | https://github.com/apache/flink/pull/26001 |
| `base_commit` | `180d587717ba0997c35f89e080974851eea7a938` |
| Language | Java |
| Test framework | junit-maven |
| Test level | system |
| Eval image | `lolbench/apache-flink-flip-501-pr-26001:1` |
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
| `orig` | original PR-derived hidden selectors | 5 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 22 | 2 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 27 | 52 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/apache-flink-flip-501-pr-26001:1 .
docker build -t lolbench/apache-flink-flip-501-pr-26001-coverage:1 -f coverage/Dockerfile .
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
| `coverage/` | optional instrumented coverage image recipe |
| `coverage_out/` | committed or local coverage reports |
| `test_augmentation/` | source files and audit notes for augmented tests |
| `validation_out/` | local validation output, when retained |

## Selector and validation summary

| Suite | F2P | P2P |
| --- | ---: | ---: |
| `orig` | 5 | 50 |
| `aug` | 22 | 2 |
| `union` | 27 | 52 |

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 50.6%, 680/1344, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. `orig`, `aug`, and `union` reports may coexist; the union report is the preferred audit signal when augmented tests are shipped.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `8g`
- Timeout: `7200` seconds
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

# LoLBench instance: Apache-Flink PR-26001 (FLIP-501)
Window Extension for DataStream V2 API.
F2P (5): WindowITCase in flink-tests. The two-input tumbling-window selector was removed because it directly invoked the PR-added `TwoInputNonBroadcastWindowStreamProcessFunction` symbol absent from the requirement doc.
P2P (50): flink-clients (strict §7).
Toolchain: JDK 11, Flink 2.0-SNAPSHOT.

Augmented F2P (22 selectors) adds §6-clean runtime tests to `WindowRuntimeAugITCase`
covering three previously-uncovered surfaces, all through documented public DataStream
V2 / WindowStrategy APIs (no `getTimeType`/`WindowUtils`/`.impl.` internals in any
selected body):

- **Sliding default-time and slide interval** (`testEventTimeSlidingWindowBoundsAndOverlap`,
  `testEventTimeSlidingWindowFromFourArgFactoryKeepsSlideInterval`): event-time sliding
  jobs from the documented `WindowStrategy.sliding(...)` factories asserting slide-aligned
  `[0, 5000)` bounds and one-slide overlap. Kill `mutant_002_sliding_default_processing_time`
  and m006/m007/m015.
- **Allowed-lateness / late-record handling** (`testEventTimeSlidingWindowDefaultLatenessIsZero…`,
  `testTumbling…Lateness…`, `testTwoInput/TwoOutputExplicitLateness…`): default zero allowed
  lateness drops late records, explicit lateness keeps them in-window, and the lateness
  boundary is inclusive. Kill the lateness class (m004, m005, m028, m029, m030, m031, m034,
  m038, m039, m040).
- **Two-input / two-output window records, bounds, and routing**
  (`testTwoInputTumblingContextBoundsAndBothRecordSides`,
  `testGlobalStreamTwoInputAndTwoOutputWindowRoutes`): assert `TwoInputWindowContext.getEndTime`
  and per-side `getAllRecords1`/`getAllRecords2`, plus two-output window routing. Kill m020,
  m023, m024, m025, m026, m042.

Two mutants (`mutant_032_delete_cleanup_event_timer_as_processing`,
`mutant_033_register_cleanup_event_timer_as_processing`) were removed as §6-unreachable:
they flip `WindowUtils.{register,delete}CleanupTimer` from event-time to processing-time,
but that internal cleanup-timer time domain is not observable through any documented surface
(the documented event-time + allowed-lateness tests pass identically under golden and both
mutants). The remaining 41 mutants are all killed by `union`.

The 47 additional P2P selectors are pre-existing method-level
`flink-clients` tests covering application entrypoint parsing, packaged
program setup, CLI dynamic properties, frontend info/list behavior, and
cluster-client service loading. They were verified present in the base
checkout and absent from `solution.patch` / `eval_tests.patch`.
`flink-clients` is outside the FLIP-501 DataStream V2 window-extension
changes, so these selectors guard adjacent public client behavior that
should not change.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**38.5% / 48.7% / 50.6%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

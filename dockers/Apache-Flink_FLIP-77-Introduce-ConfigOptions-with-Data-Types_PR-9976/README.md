# LoLBench instance: Apache-Flink PR-9976 (FLIP-77)

Removing config-option string parsing inconsistencies — agents must
introduce typed `ConfigOption` builders, `ReadableConfig`/`WritableConfig`
interfaces on `Configuration`, and the shared `StructuredOptionsSplitter`.

## Requirement

- FLIP: https://cwiki.apache.org/confluence/display/FLINK/FLIP-77
- JIRA: [FLINK-14491](https://issues.apache.org/jira/browse/FLINK-14491)
- PR:   https://github.com/apache/flink/pull/9976
- Merged: 2019-10-29

## Files in this bundle

| File | Role |
|------|------|
| `Dockerfile` | Layer-3 instance image (source @ base_commit + pre-built `flink-core` + `flink-clients`). |
| `base/Dockerfile` | Layer-2 toolchain image (`lolbench/flink-base-jdk8:1` — JDK 8 + Maven 3 + git + python3). |
| `spec.json` | Authoritative metadata: instance_id, base/merge SHAs, F2P/P2P selectors, triage notes. |
| `solution.patch` | Production-source diff for the PR's single FLINK-14493 commit. Agents must reconstruct an equivalent diff. |
| `eval_tests.patch` | Test-source diff for the same commit. Applied internally by `run_tests.sh` after the production build; never given to agents. |
| `f2p.txt`, `p2p.txt` | Plain-text test selectors mirroring `spec.json`. |
| `run_tests.sh` | Container entrypoint: applies patches, builds, runs Surefire, emits `/out/agent_report.json`. |
| `eval.sh` | User-facing wrapper for an evaluator with one solution.patch. |
| `validate.sh` | Bundle-author tool: runs both `validate_pre` and `validate_post` and asserts the §7 invariant. |
| `coverage/` | Placeholder for a future separate coverage-instrumentation image. Empty for now. |

## Base / merge commits

| Role | SHA |
|------|-----|
| `base_commit` (this bundle) | `005bda9be361ffe6c371ebefed32e614cbacd876` |
| `base_commit` (GitHub PR-base) | `96640cad3d770756cb6e70c73b25bd4269065775` |
| `merge_commit_sha` | `b7cd6a984750d7dd98e6408f3703b1978b14355a` |
| PR's actual commit | `b7cd6a984750d7dd98e6408f3703b1978b14355a` |

`96640cad…` is what GitHub reports as the PR's base.
Between that commit and `b7cd6a98`, four unrelated commits (FLINK-14397
Hive UDTF, FLINK-14134 LimitableTableSource ×2, FLINK-13513 ML
Mapper) landed on master.  We anchor at `parent(b7cd6a98) = 005bda9b`
so `solution.patch` contains *only* the FLIP-77 work.

## Build instructions (skipped — pending user approval)

```
# Layer 2 (Java-8 base, ~550 MB):
docker build -t lolbench/flink-base-jdk8:1 base/

# Layer 3 (instance, expect ~1-1.5 GB):
DOCKER_BUILDKIT=1 docker build -t lolbench/apache-flink-flip-77-pr-9976:1 .
```

## Usage

```
# As an evaluator with a candidate solution.patch:
./eval.sh path/to/solution.patch --out ./eval_out
# → ./eval_out/agent_report.json
# → prints e.g. [eval] RESOLVED  build=ok  F2P 9/9  P2P 47/47

# As bundle author verifying the §7 invariant:
./validate.sh
# → prints PASS for each invariant row.
```

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 9 | 47 |
| `aug` | mutation/coverage-driven sidecar selectors only | 4 | 3 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 13 | 50 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Test selectors

### F2P — 9 entries (5 of the 6 modified test files in the PR)

The PR modifies 6 test files; 5 are pinned here.  The 6th
(`StructuredOptionsSplitterTest`) is intentionally omitted per Codex
round-1 review — it directly exercises the package-private
`@Internal` helper `StructuredOptionsSplitter.splitEscaped(...)`,
which over-constrains valid solutions to that specific helper class
name.  Public-API parsing behavior is still covered through
`ConfigurationConversionsTest` and `ConfigurationParsingInvalidFormatsTest`,
which both go through `Configuration` / `ConfigOptions` rather than the
helper directly.

| # | Selector | Notes |
|---|----------|-------|
| 1 | `ConfigurationConversionsTest#testConversions` | NEW.  Parameterized (89 specs). |
| 2 | `ConfigurationParsingInvalidFormatsTest#testInvalidStringParsingWithGetOptional` | NEW. |
| 3 | `ConfigurationParsingInvalidFormatsTest#testInvalidStringParsingWithGet` | NEW. |
| 4 | `ConfigurationTest` | MODIFIED (−126/+0).  Class-level pin: covers all 11 remaining `@Test` methods.  In pre-state, surfaces as ERROR alongside the other F2P rows because flink-core's test-compile is module-scoped and other F2P tests in the same module reference new API. |
| 5 | `ReadableWritableConfigurationTest#testGetOptionalFromObject` | NEW.  Parameterized (11 specs). |
| 6 | `ReadableWritableConfigurationTest#testGetOptionalFromString` | NEW.  Parameterized (11 specs). |
| 7 | `ReadableWritableConfigurationTest#testGetDefaultValue` | NEW.  Parameterized (11 specs). |
| 8 | `ReadableWritableConfigurationTest#testGetOptionalDefaultValueOverride` | NEW.  Parameterized (11 specs). |
| 9 | `UnmodifiableConfigurationTest` | MODIFIED (+2/−1).  Class-level pin: covers `testOverrideAddMethods` + `testExceptionOnSet`.  Same module-scoped compile mechanism as entry #4 — surfaces as ERROR in pre-state. |

The discriminating signal in pre-state is **module-scoped test-compile
failure**: at base, `ConfigOptions.intType()`/`Configuration.get(...)`
don't yet exist; `eval_tests.patch` adds test code that references
them; Maven fails the entire flink-core test-compile phase and
Surefire produces no reports → every F2P entry surfaces as ERROR.
Post-state with `solution.patch` applied, test-compile succeeds and
every entry passes.

### P2P — 47 original method-level selectors (union P2P is 50 with sidecar)

| # | Selector |
|---|----------|
| 1 | `RestClusterClientConfigurationTest#testConfiguration` |
| 2 | `ExponentialWaitStrategyTest#testInitialWaitGreaterThanMaxWait` |
| 3 | `ExponentialWaitStrategyTest#testMaxSleepTime` |
| 4 | `ExponentialWaitStrategyTest#testExponentialGrowth` |
| 5 | `ExponentialWaitStrategyTest#testMaxAttempts` |
| 6 | `RemoteExecutorHostnameResolutionTest#testUnresolvableHostname1` |
| 7 | `RemoteExecutorHostnameResolutionTest#testUnresolvableHostname2` |
| 8 | `LeaderRetrievalServiceHostnameResolutionTest#testUnresolvableHostname1` |
| 9 | `LeaderRetrievalServiceHostnameResolutionTest#testUnresolvableHostname2` |
| 10 | `PackagedProgramTest#testExtractContainedLibraries` |
| 11 | `ExecutionEnvironmentTest#testExecuteAfterGetExecutionPlanContextEnvironment` |
| 12 | `DefaultCLITest#testConfigurationPassing` |
| 13 | `DefaultCLITest#testManualConfigurationOverride` |
| 14 | `CliFrontendListTest#testList` |
| 15 | `CliFrontendListTest#testListOptions` |
| 16 | `CliFrontendListTest#testUnrecognizedOption` |
| 17 | `CliFrontendInfoTest#testShowExecutionPlan` |
| 18 | `CliFrontendInfoTest#testShowExecutionPlanWithParallelism` |
| 19 | `CliFrontendCancelTest#testCancel` |
| 20 | `CliFrontendCancelTest#testMissingJobId` |
| 21 | `CliFrontendCancelTest#testUnrecognizedOption` |
| 22 | `CliFrontendCancelTest#testCancelWithSavepoint` |
| 23 | `CliFrontendCancelTest#testCancelWithSavepointWithoutJobId` |
| 24 | `CliFrontendCancelTest#testCancelWithSavepointWithoutParameters` |
| 25 | `CliFrontendInfoTest#testMissingOption` |
| 26 | `CliFrontendInfoTest#testUnrecognizedOption` |
| 27 | `CliFrontendPackageProgramTest#testNonExistingJarFile` |
| 28 | `CliFrontendPackageProgramTest#testFileNotJarFile` |
| 29 | `CliFrontendPackageProgramTest#testVariantWithExplicitJarAndArgumentsOption` |
| 30 | `CliFrontendPackageProgramTest#testVariantWithExplicitJarAndNoArgumentsOption` |
| 31 | `CliFrontendPackageProgramTest#testValidVariantWithNoJarAndNoArgumentsOption` |
| 32 | `CliFrontendPackageProgramTest#testNoJarNoArgumentsAtAll` |
| 33 | `CliFrontendPackageProgramTest#testNonExistingFileWithArguments` |
| 34 | `CliFrontendPackageProgramTest#testNonExistingFileWithoutArguments` |
| 35 | `CliFrontendPackageProgramTest#testPlanWithExternalClass` |
| 36 | `CliFrontendRunTest#testRun` |
| 37 | `CliFrontendRunTest#testUnrecognizedOption` |
| 38 | `CliFrontendRunTest#testInvalidParallelismOption` |
| 39 | `CliFrontendRunTest#testParallelismWithOverflow` |
| 40 | `CliFrontendSavepointTest#testTriggerSavepointSuccess` |
| 41 | `CliFrontendSavepointTest#testTriggerSavepointFailure` |
| 42 | `CliFrontendSavepointTest#testTriggerSavepointFailureIllegalJobID` |
| 43 | `CliFrontendSavepointTest#testTriggerSavepointCustomTarget` |
| 44 | `CliFrontendSavepointTest#testDisposeSavepointSuccess` |
| 45 | `CliFrontendSavepointTest#testDisposeWithJar` |
| 46 | `CliFrontendSavepointTest#testDisposeSavepointFailure` |
| 47 | `CliFrontendStopWithSavepointTest#testStopWithOnlyJobId` |

All 47 exist at `base_commit`, exercise `Configuration` only via the
existing (preserved) API, and therefore pass with or without the PR's
changes.  Spread across 14 distinct flink-clients test classes. The 3
additional sidecar P2P selectors remain in `p2p_aug.txt`; they count
toward the union total but are not mixed into `p2p.txt`.

## §7 invariant

| State | Build | F2P | P2P | `resolved` |
|-------|-------|-----|-----|------------|
| `validate_pre` | ok (source builds against unchanged tests) | 0/9 — Surefire ERROR because flink-core test-compile fails on missing methods | 47/47 PASS | false |
| `validate_post` | ok | 9/9 PASS | 47/47 PASS | true |

The trick is: `solution.patch` is applied *before* the Maven `install`
step (so test sources still compile against `Configuration`'s old
shape) and `eval_tests.patch` is applied *after* (so the build never
sees the new test code that depends on the new API).  This keeps both
states' `build.status = ok` while still differentiating F2P pre vs
post via Surefire report presence/absence.

## Toolchain notes (Flink 1.10 era)

- Java 1.8, Maven 3.x — `base/Dockerfile` uses `maven:3-eclipse-temurin-8`.
- JUnit 4.12 (no JUnit-platform involvement — different from FLIP-335 which is 5.10.1).
- Surefire 2.22.1 (pinned in Flink's parent POM).
- Surefire providers (`surefire-junit4`, `surefire-junit47`) are pre-warmed via `dependency:get` during the Layer-3 build, so eval-time `mvn test` runs offline.

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
| `f2p.txt` | original fail-to-pass selectors |
| `p2p.txt` | original pass-to-pass selectors |
| `f2p_aug.txt` | augmented fail-to-pass selectors |
| `p2p_aug.txt` | augmented pass-to-pass selectors |
| `run_tests.sh` | container entrypoint for eval and validation modes |
| `base/` | optional project base image recipe or dependency cache recipe |
| `coverage/` | optional instrumented coverage image recipe |
| `coverage_out/` | committed or local coverage reports |
| `test_augmentation/` | source files and audit notes for augmented tests |

## Coverage

- Selected coverage report: `coverage_out/coverage_report_aug.json`
- Summary: 89.3%, 234/262, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. Prefer the union report when augmented tests are available.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `7g`
- Timeout: `not recorded` seconds
- Eval-time network: disabled with `--network=none`.

## Troubleshooting

- `image not found`: build the eval image first, or use the image tag shown in this README.
- `patch_apply_failure`: regenerate the candidate patch against the exact `base_commit` recorded in `spec.json`.
- `eval_patch_apply_failure` or `eval_aug_patch_apply_failure`: the hidden test patch no longer applies cleanly on top of the candidate; treat this as bundle-maintainer work.
- `build_failure`: inspect `eval_out/run.log`; dependency downloads should not occur at eval time.
- no `agent_report.json`: inspect the last lines of `eval_out/run.log` and confirm Docker had the documented memory/CPU budget.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**85.5% / 89.31% / 89.31%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

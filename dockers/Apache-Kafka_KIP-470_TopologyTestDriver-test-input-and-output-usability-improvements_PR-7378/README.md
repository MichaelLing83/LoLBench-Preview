# LoLBench instance: Apache-Kafka PR-7378 (KIP-470)

TopologyTestDriver input/output usability — introduce the public
`TestInputTopic` and `TestOutputTopic` types that supersede the
test-only `ConsumerRecordFactory` + raw `TopologyTestDriver.pipeInput`
/ `.readOutput` round-trip.  Agents must add the new types in
`streams/test-utils/src/main/java`, hook them into `TopologyTestDriver`,
and adapt the WordCount demo + the existing `streams/`/`streams:test-utils`/
`streams-scala` tests to use the new API.

## Requirement

- KIP: https://cwiki.apache.org/confluence/display/KAFKA/KIP-470%3A+TopologyTestDriver+test+input+and+output+usability+improvements
- PR: https://github.com/apache/kafka/pull/7378
- Merged: 2019-10-07

## Files in this bundle

| File | Role |
|------|------|
| `Dockerfile` | Layer-3 instance image (source @ base_commit + warm Gradle cache + pre-compiled streams). |
| `base/Dockerfile` | Layer-2 toolchain (`lolbench/kafka-base-jdk8-gradle562:1` — JDK 8 + Gradle 5.6.2 + git + python3). |
| `spec.json` | Authoritative metadata; F2P/P2P selectors; triage notes including the documented pre-state P2P deviation. |
| `solution.patch` | Source/build diff (8 of 59 files: 7 source + `build.gradle`). |
| `eval_tests.patch` | Test-source diff (50 files across `:streams`, `:streams:test-utils`, `:streams:examples`, `:streams:streams-scala`). |
| `omitted.patch` | Documentation diff (`docs/streams/developer-guide/testing.html`). |
| `f2p.txt`, `p2p.txt` | Plain-text selectors mirroring `spec.json`. |
| `run_tests.sh` | Container entrypoint. |
| `eval.sh` | User-facing wrapper. |
| `validate.sh` | Bundle-author §7 invariant check. |
| `coverage/` | Separate one-shot coverage image (JaCoCo). |

## Base / merge commits

| Role | SHA |
|------|-----|
| `base_commit` (this bundle) | `0de61a4683b92bdee803c51211c3277578ab3edf` |
| `base_commit` (GitHub PR-base) | `9e10916abda2f2a3911b8ff50ad7f76bf1f45030` |
| `merge_commit_sha` | `a5a6938c69f4310f7ec519036f0df77d8022326a` |
| `pr_head_sha` | `50cfdc05d22d51ec9864ecb1722a461bb07a7e4a` |

## Build instructions

```bash
docker build -t lolbench/kafka-base-jdk8-gradle562:1 base/
DOCKER_BUILDKIT=1 docker build -t lolbench/apache-kafka-kip-470-pr-7378:1 .
```

## Usage

```bash
./eval.sh path/to/solution.patch --out ./eval_out
./validate.sh    # bundle-author §7 invariant
```

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 3 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 10 | 1 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 13 | 51 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Test selectors

### F2P — 3 system-level tests

| # | Selector | Change Type | Notes |
|---|----------|-------------|-------|
| 1 | `org.apache.kafka.streams.TestTopicsTest#testValue` | NEW file | `TestInputTopic.pipeInput` + `TestOutputTopic.readValue` round-trip. |
| 2 | `org.apache.kafka.streams.TestTopicsTest#testKeyValue` | NEW file | Round-trips a key-value pair. |
| 3 | `org.apache.kafka.streams.TestTopicsTest#testKeyValuesToMap` | NEW file | Uses `TestOutputTopic.readKeyValuesToMap`. |

> **Known limitation — RocksDB on ARM64.**  Kafka 2.4's `rocksdbjni` 5.18 ships
> no `arm64` native library.  `WordCountDemoTest` and the six rewritten
> `DeveloperGuideTesting` methods all build topologies backed by the default
> persistent `Stores.persistentKeyValueStore` (RocksDB) and hit
> `UnsatisfiedLinkError` on Apple-Silicon hosts.  They are recorded in
> `spec.json` `triage.f2p_intentionally_omitted` with the re-inclusion
> condition (rebuild with `--platform=linux/amd64` or bump `rocksdbjni`).
>
## Coverage report (curation-time, one-shot)

```
F2P covered : 105 / 252  (41.7%)
P2P covered :   0 / 252  (  0%)
union       : 105 / 252  (41.7%)
```

F2P below the 50% threshold.  The uncovered 147 executable lines are
overwhelmingly inside `TopologyTestDriver.java` (the new
`createInputTopic` / `createOutputTopic` factory methods + cleanup
helpers that only the RocksDB-backed tests would touch) and
`TestRecord.java` (constructors + Headers handling that
`TestRecordTest` would exercise — disqualified by `*.internals.*`
header-internals import).  Expansion candidates that **would** lift
this above 50% but are currently blocked:

- `WordCountDemoTest` + the 6 `DeveloperGuideTesting` methods — all
  use RocksDB-backed Stores, which has no ARM64 native lib in Kafka
  2.4.  Re-include after rebuilding with `--platform=linux/amd64`.
- `TestRecordTest` — imports `RecordHeader` from a `*.internals.*`
  package; re-include once `dockers/Apache-Kafka/public_surface.yaml`
  allow-lists the header-internals package.

P2P at 0% is expected: the regression suite lives in `:connect:json`,
a module unrelated to streams/test-utils where the implementation
lands.  P2P's role is to flag regressions in *other* parts of Kafka's
public API, not to overlap with the solution-patch surface.

### P2P — 50 method-level selectors (regression check, strict §7)

50 pre-existing `JsonConverterTest` selectors cover legacy public JSON conversion,
schema cache behavior, logical types, default values, decimal/date/time/timestamp
handling, and JSON output conversion. The list is stored in `p2p.txt`; no
synthesized selectors were added there.

P2P lives in `:connect:json` — a module completely independent of `:streams*`
and untouched by either patch.  Its dep chain (`:clients` main + `:connect:api` main)
is at base in both pre and post states, so test-compile + tests succeed in both
states.  This gives us strict §7 (pre P2P PASS) with no deviation.

## §7 invariant (strict)

| State | Build | F2P | P2P | `resolved` |
|-------|-------|-----|-----|------------|
| `validate_pre` | ok | 0/3 — `:streams:test-utils` test-compile fails on missing `TestInputTopic` / `TestOutputTopic` → all F2P selectors ERROR | 50/50 PASS (`:connect:json` is untouched and compiles + runs against base sources) | false |
| `validate_post` | ok | 3/3 PASS | 50/50 PASS | true |

## Toolchain notes (Kafka 2.4 era)

- Java 1.8, Scala 2.12.10, Gradle 5.6.2 (pinned in `base/Dockerfile`).
- JUnit 4.13-beta-3.
- Same `org.ajoberstar.grgit` JCenter strip as the KIP-460 bundle.
- Same `:streams:*:classes` + `:clients:jar` build pattern to avoid the
  `copyDependantLibs → :clients:compileTestJava` chain that trips
  ahead-of-test-patch builds.

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

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `8g`
- Timeout: `5400` seconds
- Eval-time network: disabled with `--network=none`.

## Troubleshooting

- `image not found`: build the eval image first, or use the image tag shown in this README.
- `patch_apply_failure`: regenerate the candidate patch against the exact `base_commit` recorded in `spec.json`.
- `eval_patch_apply_failure` or `eval_aug_patch_apply_failure`: the hidden test patch no longer applies cleanly on top of the candidate; treat this as bundle-maintainer work.
- `build_failure`: inspect `eval_out/run.log`; dependency downloads should not occur at eval time.
- no `agent_report.json`: inspect the last lines of `eval_out/run.log` and confirm Docker had the documented memory/CPU budget.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**41.67% / 91.27% / 92.46%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

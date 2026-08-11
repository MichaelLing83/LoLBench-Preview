# LoLBench Instance: Apache Flink PR-25731 (FLIP-467)

> **Requirement**: [FLIP-467](https://cwiki.apache.org/confluence/display/FLINK/FLIP-467) - "Introduce Generalized Watermarks"
> **Implementing PR**: [apache/flink#25731](https://github.com/apache/flink/pull/25731)
> **base_commit**: `f0c8f18ee09297c4c92b36d8ce7d0e0259f80178`
> **PR head**: `cb40b8ad46441836fbdac39a785d4c65d45d71be`
> **Merge commit**: `75c26e8c9fd39b957fd1e79323b4fae97b2ce4a6`
> **Language / build**: Java, Apache Maven, JDK 17

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against the FLIP-467 generalized-watermark instance,
plus the recipes used to build the eval and coverage images.

> **Status - validated 2026-06-15, then cleaned up 2026-07-09.** The Section 7 invariant passes
> end to end. In the original suite, pre-state F2P is 0/8 (8 ERROR)
> with P2P 50/50 PASSED; post-state F2P is 8/8 PASSED with P2P
> 50/50 PASSED, `resolved=true`. The historical union validation was
> F2P 13/13 PASSED plus P2P 52/52 PASSED before post-audit cleanup.
> The active suite is now 12 F2P plus 52 P2P after removing one
> hidden-internal augmented selector and unselected internal-import hunks;
> full Docker validation was not rerun after that cleanup.
>
> **Coverage.** `coverage_report.json` is complete and reports 67.2%
> union line coverage over `solution.patch` (454 / 676 executable Java
> patch lines), clearing the 50% LoLBench floor.
>
> **Why this was recoverable.** `data/lolbench_unexecutable.csv`
> previously marked this instance as `mvn_dep_cache_drift_after_3_retries`.
> That was not a structural blocker: a per-instance PR-head Maven warm
> base resolves the missing shaded Flink artifacts and Mockito version
> before offline evaluation.

---

## TL;DR - Evaluate A Solution

```bash
./eval.sh path/to/solution.patch --out eval_out
```

The wrapper writes `eval_out/agent_report.json` and prints a one-line
verdict. Exit code is `0` iff the patch is resolved, meaning every F2P
and P2P selector passed.

The evaluator receives only the sanitized public report. The F2P/P2P
selectors, `eval_tests.patch`, Maven logs, `solution.patch`, and grader
state remain on the evaluator side of the harness.

---

## 1. Bundle Layout

```
dockers/Apache-Flink_FLIP-467-Introduce-Generalized-Watermarks_PR-25731/
|-- README.md
|-- eval.sh                  # evaluator-facing wrapper
|-- validate.sh              # grader-only invariant check
|-- Dockerfile               # layer-3 eval image
|-- spec.json                # instance metadata, hashes, selectors, triage
|-- solution.patch           # 102 source/build/support files
|-- eval_tests.patch         # 1 selected system-test file: WatermarkITCase
|-- omitted.patch            # 33 non-selected test / helper / baseline files
|-- f2p.txt                  # 8 WatermarkITCase MiniCluster selectors
|-- p2p.txt                  # 50 unchanged flink-clients selectors
|-- run_tests.sh             # container entrypoint
|-- coverage_report.json     # curated JaCoCo coverage report
|-- _reconstruct_patches.py  # role-split reconstruction helper
|-- base/
|   `-- Dockerfile           # exact PR-head Maven warm base
`-- coverage/
    |-- Dockerfile           # one-shot JaCoCo coverage image
    |-- run_coverage.sh
    `-- compute_coverage.py
```

Patch reconstruction parity: 102 solution files + 1 eval-test file + 33
omitted files = 136 PR files, matching
`data/pr_files_cache/Apache-Flink_FLIP-467-Introduce-Generalized-Watermarks_PR-25731.json`.

No Docker-in-Docker, no external service, no special Linux capability,
and no network access are required at evaluation time. The containers
run with `--network=none`.

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 8 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 4 | 2 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 12 | 52 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## 2. Building The Images

```bash
# layer-2 exact Maven warm base
docker build -t lolbench/apache-flink-flip-467-base:1 -f base/Dockerfile .

# layer-3 eval image
docker build -t lolbench/apache-flink-flip-467-pr-25731:1 .

# optional one-shot coverage image
docker build -t lolbench/apache-flink-flip-467-pr-25731-coverage:1 -f coverage/Dockerfile .
```

The base image warms dependencies at PR head
`cb40b8ad46441836fbdac39a785d4c65d45d71be`, then the eval image checks
out `base_commit` and evaluates offline. This is intentional: the PR
head carries the Maven dependency graph needed by this Flink commit
family, while the scoring tree still starts from the verified base
commit.

Notable warm-cache artifacts include:

| Artifact | Why it is warmed |
| --- | --- |
| `org.apache.flink:flink-shaded-netty:4.1.100.Final-19.0` | Missing in the shared warm base that caused the original exclusion. |
| `org.apache.flink:flink-shaded-swagger:19.0` | Required by the Flink 2.0 snapshot dependency graph. |
| `org.apache.flink:flink-shaded-zookeeper-3:3.7.2-19.0` | Required by runtime/transitive test graph. |
| `org.apache.flink:flink-shaded-jackson-module-jsonSchema:2.15.3-19.0` | Required by runtime/transitive test graph. |
| `org.mockito:mockito-subclass:5.14.2` | Required by the post-PR test classpath. |
| `org.jacoco:*:0.8.12` | Needed only by the separate coverage image. |

---

## 3. Patch Split

`solution.patch` contains every hunk required to build and run the
implementation without private eval tests. It includes the new public
`org.apache.flink.api.common.watermark` API, DataStream V2 public API
hooks, runtime propagation/combination support, source-operator support,
and the required Maven/build updates.

`eval_tests.patch` intentionally contains only:

```text
flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/WatermarkITCase.java
```

That file provides the selected system-level MiniCluster scenarios. The
remaining PR test files are preserved in `omitted.patch` because they are
not part of the selected benchmark surface. Several of them are unit
tests or helper/baseline files, and applying all of them at pre-state
causes unrelated upstream test-compilation errors before P2P can be
observed. Keeping them omitted makes the private eval bundle precise
while preserving auditability.

All patch and selector hashes are recorded in `spec.json` and checked by
`run_tests.sh` at startup.

---

## 4. F2P / P2P Selection

### F2P (8 methods)

All F2P selectors are from the PR-added `WatermarkITCase`. They run
Flink MiniCluster/DataStream V2 jobs through the public execution
surface and observe generalized-watermark behavior from job output.

| Selector | What it exercises |
| --- | --- |
| `testLongWatermarkCombineMax` | Long generalized watermarks combine with max semantics. |
| `testLongWatermarkCombineMin` | Long generalized watermarks combine with min semantics. |
| `testBoolWatermarkCombineAnd` | Boolean generalized watermarks combine with AND semantics. |
| `testBoolWatermarkCombineOr` | Boolean generalized watermarks combine with OR semantics. |
| `testCombineWaitForAllChannels` | Public combine-wait-for-all-channels policy. |
| `testWatermarkHandlingResultIsPoll` | `POLL` handling suppresses downstream forwarding. |
| `testDefaultHandlingStrategyIgnore` | `IGNORE` default handling suppresses forwarding. |
| `testSourceDeclareAndEmitWatermark` | Source-level declaration and emission via public source APIs. |

Pre-state failure mode: `eval_tests.patch` materializes
`WatermarkITCase`, but the generalized-watermark API and runtime classes
do not exist yet. The selected tests therefore fail to collect/compile
as ERROR. Post-state, `solution.patch` supplies the API and runtime
implementation, and all eight tests pass.

### Excluded FLIP-467 Test Surface

The aligned-watermark `WatermarkITCase` scenario is not shipped in the
private F2P patch. It directly used `AlignableBoolWatermarkDeclaration`,
an internal runtime declaration class, so keeping it in the compiled
fixture would leak an implementation symbol contrary to the
system-test-only rule.

The augmented sidecar likewise ships only the public core-API F2P probes
and the client retry P2P probes. Unselected runtime/datastream augmented
probes were removed because Maven would still compile them and thereby
require internal watermark event/declaration classes outside the active
selector contract.

Plain `*Test.java` files under `flink-core-api`, `flink-datastream`,
`flink-runtime`, and `flink-table` are also excluded from F2P/P2P. They
directly instantiate implementation helpers or mocks and are not the
public MiniCluster/DataStream surface used by the benchmark.

### P2P (50 selectors)

P2P selectors are unchanged, pre-existing `flink-clients` tests. They
remain in `p2p.txt`; the synthesized sidecar selectors remain only in
`p2p_aug.txt`.

The expanded set covers client CLI option parsing, packaged-program
loading, application JAR entry-class discovery, application job-status
polling, dynamic properties, list/info commands, REST cluster client
configuration, and cluster-client factory discovery. See `p2p.txt` for
the exact selector list.

The runner executes P2P and F2P in separate Maven invocations. The
production install step uses `-pl flink-tests,flink-clients -am`, but
selector execution uses only `-pl <target-module>` so unrelated upstream
test trees are not compiled during scoring. This is necessary for this
PR because implementation interfaces changed in `flink-runtime`, while
non-selected runtime test helpers are intentionally omitted.

---

## 5. Validation Status

Validated on 2026-06-15 with the docker bundle matrix:

```bash
LOLBENCH_MODE=validate_pre  LOLBENCH_SUITE=<orig|aug|union> docker run ...
LOLBENCH_MODE=validate_post LOLBENCH_SUITE=<orig|aug|union> docker run ...
```

| Suite / row | Working tree | F2P | P2P | Outcome |
| --- | --- | --- | --- | --- |
| `orig validate_pre` | `base_commit + eval_tests.patch` | 0/8 PASSED, 8 ERROR | 50/50 PASSED | Matches the required pre-state invariant. |
| `orig validate_post` | `base_commit + solution.patch + eval_tests.patch` | 8/8 PASSED | 50/50 PASSED | `resolved=true`. |
| `aug validate_pre` | `base_commit + eval_tests.patch + eval_tests_aug.patch` | historical 0/5 PASSED, 5 ERROR; active count 4 | 2/2 PASSED | Historical validation predates post-audit cleanup. |
| `aug validate_post` | `base_commit + solution.patch + eval_tests.patch + eval_tests_aug.patch` | historical 5/5 PASSED; active count 4 | 2/2 PASSED | Historical validation predates post-audit cleanup. |
| `union validate_pre` | original plus augmented selectors | historical 0/13 PASSED, 13 ERROR; active count 12 | 52/52 PASSED | Historical validation predates post-audit cleanup. |
| `union validate_post` | original plus augmented selectors | historical 13/13 PASSED; active count 12 | 52/52 PASSED | Historical validation predates post-audit cleanup. |

The final invariant check printed:

```text
PASS  pre: F2P all FAIL/ERROR
PASS  pre: P2P all PASS
PASS  post: F2P all PASS
PASS  post: P2P all PASS
PASS  post: resolved=True
```

No selected test is expected to SKIP in the passing post-state.

---

## 6. Coverage

Run the one-shot coverage image with:

```bash
mkdir -p coverage_out
docker run --rm --network=none \
  -v "$(pwd)/coverage_out":/out \
  --memory 8g --cpus 4 \
  lolbench/apache-flink-flip-467-pr-25731-coverage:1
```

Coverage uses JaCoCo `0.8.12` against the post-state tree. The three
checked-in suite reports live under `coverage_out/`, and
`coverage_report.json` mirrors the union report.

| Metric | Value |
| --- | ---: |
| Lines in `solution.patch` | 3078 |
| Executable Java lines in patch | 676 |
| F2P covered | 453 |
| P2P covered | 27 |
| Union covered | 454 |
| Union coverage | 67.2% |
| Coverage complete | true |

P2P coverage is intentionally small because these selectors guard
unchanged `flink-clients` behavior, while the F2P MiniCluster scenarios
exercise the generalized-watermark implementation surface. The combined
union run clears the 50% LoLBench floor.

---

## 7. Troubleshooting

See `docs/executable_environment_plan.md` for the generic harness
contract. FLIP-467-specific notes:

- **Offline Maven failures**: rebuild the exact warm base first. The
  eval image depends on Maven artifacts warmed at PR head, not only on a
  shared Flink base.
- **P2P unexpectedly ERRORs at pre-state**: check that `eval_tests.patch`
  contains only `WatermarkITCase.java`. Applying all PR test hunks pulls
  in unit/helper test code that references implementation symbols absent
  in pre-state.
- **Post-state selector compile failures in `flink-runtime`**: selector
  Maven invocations should not use `-am`. The source install step already
  builds and installs dependencies; selector runs should stay inside
  `flink-tests` or `flink-clients`.
- **Coverage XML missing**: verify the coverage image was rebuilt after
  the eval image and that the JaCoCo artifacts exist under `/opt/jacoco`.
- **Flink hostname issues**: `run_tests.sh` and `run_coverage.sh` add the
  container hostname to `/etc/hosts` when needed, which keeps MiniCluster
  RPC setup stable under `--network=none`.

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

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**55.5% / 51.5% / 67.2%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.

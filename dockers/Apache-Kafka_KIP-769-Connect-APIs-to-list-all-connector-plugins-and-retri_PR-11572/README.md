# LoLBench Instance: Apache Kafka PR-11572 (KIP 769 Connect APIs to list all connector plugins and retri)

This directory contains the LoLBench docker bundle for evaluating an agent-generated `solution.patch` against this instance. The evaluator runs the container; the agent only submits a patch against the project source at `base_commit`.

## Instance metadata

| Field | Value |
| --- | --- |
| `instance_id` | `Apache-Kafka_KIP-769-Connect-APIs-to-list-all-connector-plugins-and-retri_PR-11572` |
| Repository / project | `apache/kafka` |
| Requirement | https://cwiki.apache.org/confluence/display/KAFKA/KIP-769 |
| Implementing PR | https://github.com/apache/kafka/pull/11572 |
| `base_commit` | `066cdc8c621dfc4d26e12ee539368d6c1eb2707f` |
| Language | Java |
| Test framework | junit-gradle |
| Test level | system |
| Eval image | `lolbench/apache-kafka-kip-769-pr-11572:1` |
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
| `orig` | original PR-derived hidden selectors | 4 | 50 |
| `aug` | mutation/coverage-driven sidecar selectors only | 5 | 1 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 9 | 51 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

```bash
./eval.sh path/to/solution.patch --suite orig
./eval.sh path/to/solution.patch --suite aug
./eval.sh path/to/solution.patch --suite union
```

## Docker images

```bash
docker build -t lolbench/apache-kafka-kip-769-pr-11572:1 .
docker build -t lolbench/apache-kafka-kip-769-pr-11572-coverage:1 -f coverage/Dockerfile .
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
| `orig` | 4 | 50 |
| `aug` | 5 | 1 |
| `union` | 9 | 51 |

Validation follows the LoLBench invariant: pre-state applies hidden eval tests without the solution and expects F2P to fail or error while P2P passes; post-state applies the reference solution plus hidden tests and expects all selected tests to pass.

## Coverage

- Selected coverage report: `coverage_out/coverage_report_union.json`
- Summary: 77.8%, 70/90, coverage_complete=true

Coverage is measured against executable lines or statements introduced by `solution.patch`. `orig`, `aug`, and `union` reports may coexist; the union report is the preferred audit signal when augmented tests are shipped.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `8g`
- Timeout: `5400` seconds
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

# LoLBench instance: Apache-Kafka PR-11572 (KIP-769)

Adds two new public REST endpoints to the Kafka Connect REST API:
- `GET /connector-plugins` extended to list **all** plugin types
  (Connector, Transformation, Converter, Predicate) — not just Connectors.
- `GET /connector-plugins/{plugin}/config` returns the plugin's `ConfigDef`.

Plus the `PluginInfo` response shape gains `class_type` and `version`.

## Requirement

- KIP: https://cwiki.apache.org/confluence/display/KAFKA/KIP-769
- PR: https://github.com/apache/kafka/pull/11572
- Merged: 2022-03-03

## Test selectors

### F2P - 4 original tests (all in `:connect:runtime`)

Three original F2P selectors were removed during the 2026-06-08
Source-Symbol audit because their selected bodies directly named
PR-added source symbols not spelled out in the requirement document:
`className`, `connectorPluginConfig`, and `NoVersionFilter`.

| # | Selector |
|---|----------|
| 1 | `org.apache.kafka.connect.runtime.rest.resources.ConnectorPluginsResourceTest#testListConnectorPlugins` |
| 2 | `org.apache.kafka.connect.runtime.rest.resources.ConnectorPluginsResourceTest#testListAllPlugins` |
| 3 | `org.apache.kafka.connect.runtime.AbstractHerderTest#testConfigValidationTransformsExtendResults` |
| 4 | `org.apache.kafka.connect.runtime.AbstractHerderTest#testConfigValidationPredicatesExtendResults` |

### P2P — 50 selectors (strict §7, `:connect:json` untouched)

| # | Selector |
|---|----------|
| 1 | `org.apache.kafka.connect.json.JsonConverterTest#testConnectSchemaMetadataTranslation` |
| 2 | `org.apache.kafka.connect.json.JsonConverterTest#testCacheSchemaToConnectConversion` |
| 3 | `org.apache.kafka.connect.json.JsonConverterTest#testJsonSchemaCacheSizeFromConfigFile` |

## Toolchain (Kafka 3.2 era)

- Java 11, Scala 2.13.6, Gradle 7.3.3, jacoco 0.8.7.

## Build

```bash
docker build -t lolbench/kafka-base-jdk11-gradle733:1 base/
DOCKER_BUILDKIT=1 docker build -t lolbench/apache-kafka-kip-769-pr-11572:1 .
```

## §7 invariant (strict)

| State | Build | F2P | P2P | `resolved` |
|-------|-------|-----|-----|------------|
| `validate_pre` | ok | 0/4 ERROR — `:connect:runtime` test-compile fails (eval_tests.patch references new public types) | 50/50 PASS (`:connect:json` untouched) | false |
| `validate_post` | ok | 4/4 PASS | 50/50 PASS | true |

Under `LOLBENCH_SUITE=union` the F2P set is the 4 original selectors plus
the 5 augmented selectors (9 total) and P2P is 51: `validate_pre` →
9 ERROR / 51 PASS (`resolved=false`); `validate_post` → 9 PASS / 51 PASS
(`resolved=true`).

## Augmented suite — mutant kills (§6-clean)

The augmented sidecar ships **5 new F2P** (mutation-kill) selectors plus
the pre-existing **1 synthesized P2P** selector. Every augmented F2P body
names only documented public surface (the `GET /connector-plugins[/…/config]`
REST paths and their documented response, `ConfigKeyInfo`, the documented
lowercase plugin `type` values, the documented `connectorsOnly` default,
and the documented `Converter.config()` default) — never a PR-added
internal symbol (`getConnectorConfigDef`, `connectorPluginConfig`,
`newPlugin`, `convertConfigKey`, `PluginType`, `PluginInfo`,
`sinkConnectors`/`sourceConnectors`/`headerConverters`,
`addConnectorPlugins`).

| Augmented F2P | Level | Kills |
|---|---|---|
| `ConnectorPluginsListDefaultAugTest#testConnectorsOnlyQueryParamDefaultsToTrue` | module (reflection) | mutant_001 |
| `ConverterDefaultConfigAugTest#testDefaultConfigReturnsNonNullEmptyConfigDef` | unit (public iface) | mutant_011 |
| `ConnectorPluginsConfigEndpointAugIntegrationTest#testTransformationConfigEndpointExposesDocumentedKey` | system (EmbeddedConnectCluster) | mutant_010, mutant_013 |
| `ConnectorPluginsConfigEndpointAugIntegrationTest#testConverterConfigEndpointExposesDocumentedKey` | system (EmbeddedConnectCluster) | mutant_010, mutant_012 |
| `ConnectorPluginsConfigEndpointAugIntegrationTest#testListAllPluginsExposeDocumentedLowercaseTypes` | system (EmbeddedConnectCluster) | mutant_009 |

Full union sweep result: all **9** committed mutants in
`mutations/<instance>/` report `resolved=false` (killed).

## Coverage report (curation-time, one-shot)

```
F2P covered : 27 / 90  (30.0%)   (orig f2p only)
union       : 70 / 90  (77.8%)   (orig + augmented sidecar)
```

The augmented union suite raises solution.patch coverage to 77.8% (up
from 55.6%) because the new system-level
`ConnectorPluginsConfigEndpointAugIntegrationTest` boots an
`EmbeddedConnectCluster` and drives the real
`GET /connector-plugins/<plugin>/config` dispatch and plugin-scan path.
Union remains just below the historical 80% gate; the primary
augmentation gate — every committed mutant killed under
`LOLBENCH_SUITE=union` — passes for all 9 mutants.

| File | exec lines | union covered |
|------|-----------:|--------------:|
| `ConnectorPluginsResource.java`   |  22 |  22 (100%) |
| `PluginInfo.java`                 |   9 |   6 ( 67%) |
| `PluginType.java`                 |   2 |   2 (100%) |
| `VerifiableSinkConnector.java`    |   1 |   1 (100%) |
| `AbstractHerder.java`             |  23 |  14 ( 61%) |
| `Plugins.java`                    |  11 |   5 ( 45%) |
| `DelegatingClassLoader.java`      |  16 |  14 ( 88%) |
| `PluginScanResult.java`           |   5 |   5 (100%) |

With the augmented union suite, the system-level integration test now
reaches `AbstractHerder.connectorPluginConfig`, the
`ConnectorPluginsResource` config endpoint, and the
`Plugins`/`DelegatingClassLoader`/`PluginScanResult` plugin-scan path via
the embedded cluster's classpath scan.  The remaining uncovered lines are
predicate/header-converter branches and error paths not reached by the
selected plugins.  The discriminating signal (all 9 committed mutants
killed under `union`, post-state F2P all PASS) is intact.

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**30.0% / 32.2% / 77.8%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`. The aug-only per-suite report was not regenerated this pass; the union report reflects the refreshed augmented sidecar.

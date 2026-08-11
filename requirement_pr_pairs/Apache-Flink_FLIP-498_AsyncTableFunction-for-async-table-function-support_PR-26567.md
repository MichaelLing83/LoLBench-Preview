# Apache Flink - FLIP-498: AsyncTableFunction for async table function support

**PR:** https://github.com/apache/flink/pull/26567
**Requirement Doc:** https://cwiki.apache.org/confluence/display/FLINK/FLIP-498

## Matching Statistics
- **Requirement Doc Coverage:** 6/6 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 32/67 files mapped (47.8%) + 35/67 files associated (52.2%) = 67/67 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | FLIP-498: AsyncTableFunction for async table function support | No | N/A | knowledge |
| 2 | Motivation | No | N/A | contextual |
| 3 | Scope | No | N/A | knowledge |
| 4 | Public Interfaces | Yes | Yes | implementation |
| 5 | Proposed Changes | No | N/A | knowledge |
| 6 | Proposed Changes > Planner Changes | No | N/A | knowledge |
| 7 | Proposed Changes > Planner Changes > Split Rules | Yes | Yes | implementation |
| 8 | Proposed Changes > Planner Changes > Physical Rules | Yes | Yes | implementation |
| 9 | Proposed Changes > Runtime Changes | No | N/A | knowledge |
| 10 | Proposed Changes > Runtime Changes > Code Generation | Yes | Yes | implementation |
| 11 | Proposed Changes > Runtime Changes > Operator | Yes | Yes | implementation |
| 12 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 13 | Test Plan | Yes | Yes | evaluation |
| 14 | Rejected Alternatives | No | N/A | contextual |
| 15 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support | No | N/A | knowledge |
| 16 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Motivation | No | N/A | contextual |
| 17 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Scope | No | N/A | knowledge |
| 18 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Public Interfaces | No | N/A | knowledge |
| 19 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes | No | N/A | knowledge |
| 20 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Planner Changes | No | N/A | knowledge |
| 21 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Planner Changes > Split Rules | No | N/A | knowledge |
| 22 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Planner Changes > Physical Rules | No | N/A | knowledge |
| 23 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Planner Changes > Disallowing Async functionality when not supported | No | N/A | knowledge |
| 24 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Runtime Changes | No | N/A | knowledge |
| 25 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Runtime Changes > Code Generation | No | N/A | knowledge |
| 26 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Proposed Changes > Runtime Changes > Operator | No | N/A | knowledge |
| 27 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 28 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Test Plan | No | N/A | knowledge |
| 29 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Rejected Alternatives | No | N/A | contextual |
| 30 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Rejected Alternatives > AsyncTableFunction using a lookup Join | No | N/A | contextual |
| 31 | Linked FLIP-400 — AsyncScalarFunction for asynchronous scalar function support > Rejected Alternatives > Polymorphic table function | No | N/A | contextual |
| 32 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction | No | N/A | knowledge |
| 33 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Motivation | No | N/A | contextual |
| 34 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Motivation > Perform async operation with lookup join | No | N/A | knowledge |
| 35 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Motivation > Perform async operation by join table function | No | N/A | knowledge |
| 36 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Public Interfaces | No | N/A | knowledge |
| 37 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Public Interfaces > AsyncTableFunction | No | N/A | knowledge |
| 38 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Public Interfaces > ConfigOption | No | N/A | knowledge |
| 39 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Public Interfaces > ConfigOption > Hint | No | N/A | knowledge |
| 40 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Proposed Changes | No | N/A | knowledge |
| 41 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Performance | No | N/A | contextual |
| 42 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 43 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Test Plan | No | N/A | knowledge |
| 44 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Rejected Alternatives | No | N/A | contextual |
| 45 | Linked FLIP-313 — Add support of User Defined AsyncTableFunction > Rejected Alternatives > Job level config | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `docs/layouts/shortcodes/generated/execution_config_configuration.html` | documentation | — | Section 4 |
| 2 | `flink-core/src/main/java/org/apache/flink/api/java/typeutils/TypeExtractionUtils.java` | source | Section 4 | — |
| 3 | `flink-core/src/test/java/org/apache/flink/api/java/typeutils/TypeExtractionUtilsTest.java` | test | Section 13 | — |
| 4 | `flink-table/flink-table-api-java/src/main/java/org/apache/flink/table/api/config/ExecutionConfigOptions.java` | source | Section 4 | — |
| 5 | `flink-table/flink-table-common/src/main/java/org/apache/flink/table/functions/UserDefinedFunctionHelper.java` | source | Section 4 | — |
| 6 | `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/FunctionMappingExtractor.java` | source | Section 4 | — |
| 7 | `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/TypeInferenceExtractor.java` | source | Section 4 | — |
| 8 | `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/inference/SystemTypeInference.java` | source | — | Section 4 |
| 9 | `flink-table/flink-table-common/src/test/java/org/apache/flink/table/functions/UserDefinedFunctionHelperTest.java` | test | Section 13 | — |
| 10 | `flink-table/flink-table-common/src/test/java/org/apache/flink/table/types/extraction/TypeInferenceExtractorTest.java` | test | Section 13 | — |
| 11 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/catalog/FunctionCatalogOperatorTable.java` | source | — | Section 4 |
| 12 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGenerator.java` | source | Section 10 | — |
| 13 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/expressions/converter/FunctionDefinitionConvertRule.java` | source | — | Section 4 |
| 14 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/functions/bridging/BridgingSqlFunction.java` | source | — | Section 4 |
| 15 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/common/CommonExecAsyncCorrelate.java` | source | Section 11 | — |
| 16 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/stream/StreamExecAsyncCorrelate.java` | source | Section 11 | — |
| 17 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/logical/FlinkLogicalTableFunctionScan.java` | source | Section 8 | — |
| 18 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/physical/stream/StreamPhysicalAsyncCalc.java` | source | — | Section 7 |
| 19 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/physical/stream/StreamPhysicalAsyncCorrelate.java` | source | Section 8 | — |
| 20 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRule.java` | source | — | Section 7 |
| 21 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRule.java` | source | Section 7 | — |
| 22 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/PythonCorrelateSplitRule.java` | source | Section 7 | — |
| 23 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/RemoteCorrelateSplitRule.java` | source | Section 7 | — |
| 24 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalAsyncCalcRule.java` | source | — | Section 8 |
| 25 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalAsyncCorrelateRule.java` | source | Section 8 | — |
| 26 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalConstantTableFunctionScanRule.java` | source | — | Section 8 |
| 27 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncScalarUtil.java` | source | — | Section 11 |
| 28 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncTableUtil.java` | source | Section 11 | — |
| 29 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncUtil.java` | source | Section 11 | — |
| 30 | `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/ExecNodeMetadataUtil.java` | source | — | Section 11 |
| 31 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/codegen/ExpressionReducer.scala` | source | — | Section 7 |
| 32 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/codegen/calls/BridgingFunctionGenUtil.scala` | source | Section 10 | — |
| 33 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/FlinkStreamRuleSets.scala` | source | Section 8 | — |
| 34 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/PythonCalcSplitRule.scala` | source | — | Section 7 |
| 35 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/RemoteCalcSplitRule.scala` | source | — | Section 7 |
| 36 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/RemoteCallFinder.java` | source | Section 7 | — |
| 37 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/SplitPythonConditionFromJoinRule.scala` | source | — | Section 7 |
| 38 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/SplitRemoteConditionFromJoinRule.scala` | source | — | Section 7 |
| 39 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalCalcRule.scala` | source | — | Section 8 |
| 40 | `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalCorrelateRule.scala` | source | Section 8 | — |
| 41 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGeneratorTest.java` | test | Section 13 | — |
| 42 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/nodes/exec/stream/AsyncCorrelateRestoreTest.java` | test | Section 13 | — |
| 43 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/nodes/exec/stream/AsyncCorrelateTestPrograms.java` | test | — | Section 13 |
| 44 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRuleTest.java` | test | Section 13 | — |
| 45 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRuleTest.java` | test | Section 13 | — |
| 46 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/utils/AsyncUtilTest.java` | test | Section 13 | — |
| 47 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/runtime/stream/table/AsyncCorrelateITCase.java` | test | Section 13 | — |
| 48 | `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/runtime/utils/JavaUserDefinedTableFunctions.java` | test | — | Section 13 |
| 49 | `flink-table/flink-table-planner/src/test/resources/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRuleTest.xml` | test-data | — | Section 13 |
| 50 | `flink-table/flink-table-planner/src/test/resources/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRuleTest.xml` | test-data | — | Section 13 |
| 51 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-catalog-func/plan/async-correlate-catalog-func.json` | test-data | — | Section 13 |
| 52 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-catalog-func/savepoint/_metadata` | test-data | — | Section 13 |
| 53 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-exception/plan/async-correlate-exception.json` | test-data | — | Section 13 |
| 54 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-exception/savepoint/_metadata` | test-data | — | Section 13 |
| 55 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-join-filter/plan/async-correlate-join-filter.json` | test-data | — | Section 13 |
| 56 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-join-filter/savepoint/_metadata` | test-data | — | Section 13 |
| 57 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-left-join/plan/async-correlate-left-join.json` | test-data | — | Section 13 |
| 58 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-left-join/savepoint/_metadata` | test-data | — | Section 13 |
| 59 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-system-func/plan/async-correlate-system-func.json` | test-data | — | Section 13 |
| 60 | `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-system-func/savepoint/_metadata` | test-data | — | Section 13 |
| 61 | `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/plan/stream/sql/join/LookupJoinTest.scala` | test | — | Section 13 |
| 62 | `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/plan/utils/lookupFunctions.scala` | test | — | Section 13 |
| 63 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/calc/async/AsyncFunctionRunner.java` | source | — | Section 11 |
| 64 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/calc/async/DelegatingAsyncResultFuture.java` | source | — | Section 10 |
| 65 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/AsyncCorrelateRunner.java` | source | Section 11 | — |
| 66 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/DelegatingAsyncTableResultFuture.java` | source | Section 10 | — |
| 67 | `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/aggregate/correlate/AsyncCorrelateRunnerTest.java` | test | Section 13 | — |

---

## Section 4: Public Interfaces
*Classification: Implementable*

> The API is unchanged from how `AsyncTableFunction`s are defined for lookup joins with a couple small exceptions. Lookup joins support inferring the input and output types based on `LookupCallContext` and so a generic `Row` can be used without specifying what it contains. This FLIP won’t cover those cases, but the more straightforward ones where both arguments and output types are well specified, as with a conventional `TableFunction`. For example:
>
>   * An explicit hint with a `Row` type, as here for the output:
>
>   * For output, a single field of any non-`Row` type can be used and it will be implicitly wrapped in a `Row` :
>
> New configurations will be introduced for the functionality, identical in nature to `table.exec.async-scalar.*` :
>
> Specifically, the following new configurations will be added:
>
> **Name (Prefix** _**table.exec.async-table**_)| **Meaning**
> ---|---
> buffer-capacity| The number of outstanding requests the operator allows at once
> timeout| The total time which can pass before the invocation (including retries) is considered timed out and task execution is failed
> retry-strategy| FIXED_DELAY is for a retry after a fixed amount of time
> retry-delay| The time to wait between retries for the FIXED_DELAY strategy. Could be the base delay time for a (not yet proposed) exponential backoff.
> max-attempts| The maximum number of attempts while retrying.

#### Requirement Summary
This section specifies the public API for using `AsyncTableFunction` in correlate queries. It describes how the existing `AsyncTableFunction` class is exposed as a full UDF type (with explicit type hints or implicit Row wrapping), and introduces new `table.exec.async-table.*` configuration options (buffer-capacity, timeout, retry-strategy, retry-delay, max-attempts) mirroring the existing `table.exec.async-scalar.*` configs. The PR implements the configuration options in `ExecutionConfigOptions`, extends the type extraction utilities to handle `AsyncTableFunction` eval methods, and updates the UDF validation helper to recognize `AsyncTableFunction` as a valid correlate function type.

**File proportion:** 5/67 files mapped (7.5%) + 5/67 files associated (7.5%) = 10/67 accounted (14.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-table/flink-table-api-java/src/main/java/org/apache/flink/table/api/config/ExecutionConfigOptions.java` | Modified | +44 / -1 | `ExecutionConfigOptions` | — |
| `flink-core/src/main/java/org/apache/flink/api/java/typeutils/TypeExtractionUtils.java` | Modified | +25 / -0 | `TypeExtractionUtils` | `TypeExtractionUtils.isGenericOfClass`, `TypeExtractionUtils.getParameterizedType` |
| `flink-table/flink-table-common/src/main/java/org/apache/flink/table/functions/UserDefinedFunctionHelper.java` | Modified | +31 / -11 | `UserDefinedFunctionHelper` | `UserDefinedFunctionHelper.validateImplementationMethods`, `UserDefinedFunctionHelper.validateAsyncImplementationMethod` |
| `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/FunctionMappingExtractor.java` | Modified | +23 / -3 | `FunctionMappingExtractor` | `FunctionMappingExtractor.createParameterAndCompletableFutureVerification` |
| `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/TypeInferenceExtractor.java` | Modified | +2 / -2 | `TypeInferenceExtractor` | `TypeInferenceExtractor.forAsyncScalarFunction`, `TypeInferenceExtractor.forAsyncTableFunction` |

#### Modification Summary
- **`flink-table/flink-table-api-java/src/main/java/org/apache/flink/table/api/config/ExecutionConfigOptions.java`**: Adds the new `table.exec.async-table.*` configuration options (buffer-capacity, timeout, retry-strategy, retry-delay, max-attempts) as specified in the Public Interfaces table.
- **`flink-core/src/main/java/org/apache/flink/api/java/typeutils/TypeExtractionUtils.java`**: Extends the type extraction utility to resolve methods on `AsyncTableFunction` subclasses, enabling the framework to extract input and output type information from `eval` methods.
- **`flink-table/flink-table-common/src/main/java/org/apache/flink/table/functions/UserDefinedFunctionHelper.java`**: Updates the UDF validation and registration logic to recognize `AsyncTableFunction` as a valid function type for correlate queries, not just lookup joins.
- **`flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/FunctionMappingExtractor.java`**: Extends the function mapping extraction to support `AsyncTableFunction` eval methods, handling the `CompletableFuture` return type and implicit Row wrapping for output types.
- **`flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/extraction/TypeInferenceExtractor.java`**: Updates the type inference extractor to handle `AsyncTableFunction` alongside existing function types.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `docs/layouts/shortcodes/generated/execution_config_configuration.html` | Modified | +31 / -1 | Auto-generated documentation for new configuration options | — | — |
| `flink-table/flink-table-common/src/main/java/org/apache/flink/table/types/inference/SystemTypeInference.java` | Modified | +3 / -1 | Type inference system updated to support the new AsyncTableFunction type extraction | `SystemTypeInference` | `SystemTypeInference.deriveSystemOutputStrategy` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/catalog/FunctionCatalogOperatorTable.java` | Modified | +3 / -1 | Catalog operator-table broadens function-kind recognition so async table functions are exposed in catalog lookup | `FunctionCatalogOperatorTable` | `FunctionCatalogOperatorTable.verifyFunctionKind` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/expressions/converter/FunctionDefinitionConvertRule.java` | Modified | +1 / -0 | Conversion rule classifies the new `AsyncTableFunction` kind so it converts through the planner expressions pipeline | `FunctionDefinitionConvertRule` | `FunctionDefinitionConvertRule.convert` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/functions/bridging/BridgingSqlFunction.java` | Modified | +4 / -1 | Bridging SQL function recognizes async table functions when bridging Calcite operators to Flink function definitions | `BridgingSqlFunction` | `BridgingSqlFunction.of` |

---

## Section 7: Split Rules
*Path: Proposed Changes > Planner Changes > Split Rules*
*Classification: Implementable*

> One of the guiding philosophies to simplify code generation is to allow only a single call (the main async one) at a time at the given operator. To do this, we would like to split out any other calls to their own calcs.
>
> There is an existing rule `PythonCorrelateSplitRule` which is useful for splitting things out from corrolates to their own calc. This should be factored out to be reusable as `RemoteCorrelateSplitRule`, taking a `RemoteCalcCallFinder`, which can be passed an instance looking for async table function calls.
>
> Example SQL:
>
> **Original RelNode**| **Becomes**  
> ---|---  
> `FlinkLogicalCorrelate:`  
> ` left: FlinkLogicalCalc: projections: f0`  
> ` right: FlinkLogicalTableFunctionScan `  
> ` call: asyncTable(scalarFunction($cor0.f0))`| `FlinkLogicalCorrelate:`  
> ` left: FlinkLogicalCalc: projections: f1, scalarFunction(f1) as f0`  
> ` right: FlinkLogicalTableFunctionScan`  
> ` call: asyncTable($1)`

#### Requirement Summary
This section specifies factoring the existing `PythonCorrelateSplitRule` into a reusable `RemoteCorrelateSplitRule` that takes a `RemoteCalcCallFinder`, and creating an `AsyncCorrelateSplitRule` instance to split non-async calls out of correlates containing async table function calls. The PR implements the `RemoteCorrelateSplitRule` as a generalized base, refactors `PythonCorrelateSplitRule` to delegate to it, and adds `AsyncCorrelateSplitRule` with an async table function call finder via `RemoteCallFinder`.

**File proportion:** 4/67 files mapped (6.0%) + 7/67 files associated (10.4%) = 11/67 accounted (16.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/RemoteCorrelateSplitRule.java` | Modified | +5 / -5 | `RemoteCorrelateSplitRule`, `Config` | `RemoteCorrelateSplitRule.RemoteCorrelateSplitRule`, `RemoteCorrelateSplitRule.visitCall`, `Config.callFinder`, `Config.createDefault` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRule.java` | Modified | +10 / -4 | `AsyncCorrelateSplitRule` | — |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/PythonCorrelateSplitRule.java` | Modified | +1 / -2 | `PythonCorrelateSplitRule` | — |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/RemoteCallFinder.java` | Renamed | +1 / -1 | `RemoteCallFinder` | — |

#### Modification Summary
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/RemoteCorrelateSplitRule.java`**: Refactored as the generalized base correlate split rule that takes a `RemoteCalcCallFinder` to identify which calls need to be split out, as specified in the requirement.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRule.java`**: Updated to use the generalized `RemoteCorrelateSplitRule` with an async table function call finder, implementing the split behavior described in the requirement's RelNode transformation example.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/PythonCorrelateSplitRule.java`**: Refactored to delegate to the generalized `RemoteCorrelateSplitRule` instead of containing its own split logic.
- **`flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/RemoteCallFinder.java`**: Renamed/updated to provide the `RemoteCalcCallFinder` interface used by both Python and async correlate split rules.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRule.java` | Modified | +9 / -48 | Refactored to share common async call detection logic with the new correlate split rule | `AsyncCalcSplitRule`, `AsyncRemoteCalcCallFinder`, `AsyncCalcSplitNestedRule`, `AsyncCalcSplitOnePerCalcRule` | `AsyncRemoteCalcCallFinder.containsRemoteCall`, `AsyncRemoteCalcCallFinder.containsNonRemoteCall`, `AsyncRemoteCalcCallFinder.isRemoteCall`, `AsyncRemoteCalcCallFinder.isNonRemoteCall`, `AsyncRemoteCalcCallFinder.getName`, `AsyncRemoteCalcCallFinder.equals`, `AsyncRemoteCalcCallFinder.hashCode`, `AsyncCalcSplitRule.hasNestedCalls`, `AsyncCalcSplitNestedRule.AsyncCalcSplitNestedRule`, `AsyncCalcSplitOnePerCalcRule.AsyncCalcSplitOnePerCalcRule`, `AsyncCalcSplitOnePerCalcRule.needConvert` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/physical/stream/StreamPhysicalAsyncCalc.java` | Modified | +2 / -2 | Updated to use shared async utility methods after refactoring | `StreamPhysicalAsyncCalc` | `StreamPhysicalAsyncCalc.translateToExecNode` |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/PythonCalcSplitRule.scala` | Modified | +4 / -4 | Updated to use the refactored RemoteCalcCallFinder interface | `PythonCalcSplitPandasInProjectionRule`, `PythonRemoteCalcCallFinder`, `PythonRemoteCallFinder`, `PythonCalcSplitRule` | `PythonRemoteCalcCallFinder.equals`, `PythonRemoteCallFinder.equals` |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/RemoteCalcSplitRule.scala` | Modified | +11 / -13 | Generalized to work with the new RemoteCalcCallFinder abstraction | `RemoteCalcSplitRuleBase`, `RemoteCalcSplitConditionRule`, `RemoteCalcSplitProjectionRuleBase`, `RemoteCalcSplitRexFieldRuleBase`, `RemoteCalcSplitProjectionRexFieldRule`, `RemoteCalcSplitConditionRexFieldRule`, `RemoteCalcSplitProjectionRule`, `RemoteCalcExpandProjectRule`, `RemoteCalcPushConditionRule`, `RemoteCalcRewriteProjectionRule`, `ScalarFunctionSplitter` | — |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/SplitPythonConditionFromJoinRule.scala` | Modified | +1 / -1 | Updated import for renamed RemoteCallFinder | `SplitPythonConditionFromJoinRule` | — |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/logical/SplitRemoteConditionFromJoinRule.scala` | Modified | +1 / -1 | Updated import for renamed RemoteCallFinder | `SplitRemoteConditionFromJoinRule` | — |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/codegen/ExpressionReducer.scala` | Modified | +2 / -2 | Optimizer constant-folding guard broadened to skip reducing async (table-function) calls during planner optimization | `ExpressionReducer` | `ExpressionReducer.skipAndValidateExprs` |

---

## Section 8: Physical Rules
*Path: Proposed Changes > Planner Changes > Physical Rules*
*Classification: Implementable*

> There will also need to be a `StreamPhysicalAsyncCorrelateRule`, which converts `FlinkLogicalCorrelate`s to `StreamPhysicalAsyncCorrelate`s. This will check for the existence of any async table function calls in the correlate call to determine whether to do that conversion.

#### Requirement Summary
This section specifies creating `StreamPhysicalAsyncCorrelateRule` to convert `FlinkLogicalCorrelate` nodes into `StreamPhysicalAsyncCorrelate` nodes when async table function calls are detected. The PR implements the rule class, adds the `StreamPhysicalAsyncCorrelate` physical node, registers the rule in `FlinkStreamRuleSets`, and updates the existing `StreamPhysicalCorrelateRule` to exclude async correlates.

**File proportion:** 5/67 files mapped (7.5%) + 3/67 files associated (4.5%) = 8/67 accounted (11.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalAsyncCorrelateRule.java` | Added | +142 / -0 | `StreamPhysicalAsyncCorrelateRule` | `StreamPhysicalAsyncCorrelateRule.StreamPhysicalAsyncCorrelateRule`, `StreamPhysicalAsyncCorrelateRule.findAsyncTableFunction`, `StreamPhysicalAsyncCorrelateRule.matches`, `StreamPhysicalAsyncCorrelateRule.convert`, `StreamPhysicalAsyncCorrelateRule.convertToCorrelate` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/physical/stream/StreamPhysicalAsyncCorrelate.java` | Added | +95 / -0 | `StreamPhysicalAsyncCorrelate` | `StreamPhysicalAsyncCorrelate.StreamPhysicalAsyncCorrelate`, `StreamPhysicalAsyncCorrelate.copy`, `StreamPhysicalAsyncCorrelate.translateToExecNode` |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/FlinkStreamRuleSets.scala` | Modified | +7 / -4 | `FlinkStreamRuleSets` | — |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalCorrelateRule.scala` | Modified | +8 / -4 | `StreamPhysicalCorrelateRule` | `StreamPhysicalCorrelateRule.findTableFunction`, `StreamPhysicalCorrelateRule.matches`, `StreamPhysicalCorrelateRule.convertToCorrelate` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/logical/FlinkLogicalTableFunctionScan.java` | Modified | +1 / -0 | `Converter` | `Converter.matches` |

#### Modification Summary
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalAsyncCorrelateRule.java`**: Adds the new `StreamPhysicalAsyncCorrelateRule` that checks for async table function calls in the correlate and converts `FlinkLogicalCorrelate` to `StreamPhysicalAsyncCorrelate`, as specified in the requirement.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/physical/stream/StreamPhysicalAsyncCorrelate.java`**: Adds the `StreamPhysicalAsyncCorrelate` physical node class that represents an async correlate operation in the physical execution plan.
- **`flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/FlinkStreamRuleSets.scala`**: Registers `StreamPhysicalAsyncCorrelateRule` and `AsyncCorrelateSplitRule` in the stream rule sets so they are applied during query optimization.
- **`flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalCorrelateRule.scala`**: Updates the existing correlate rule to exclude async table function calls, deferring those to the new `StreamPhysicalAsyncCorrelateRule`.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/logical/FlinkLogicalTableFunctionScan.java`**: Adds support for identifying async table function calls in the logical table function scan node.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalAsyncCalcRule.java` | Modified | +2 / -2 | Updated to use shared async utility after refactoring | `StreamPhysicalAsyncCalcRule` | `StreamPhysicalAsyncCalcRule.matches` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalConstantTableFunctionScanRule.java` | Modified | +14 / -0 | Updated to handle async table functions in constant table function scan paths | `StreamPhysicalConstantTableFunctionScanRule` | `StreamPhysicalConstantTableFunctionScanRule.onMatch` |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/plan/rules/physical/stream/StreamPhysicalCalcRule.scala` | Modified | +1 / -2 | Updated to use shared async detection utility | — | — |

---

## Section 10: Code Generation
*Path: Proposed Changes > Runtime Changes > Code Generation*
*Classification: Implementable*

> The primary change is to extends `DelegatingResultFuture`, which currently handles just lookup joins, to handle wrapping the result in a `Row` if appropriate since we now handle implicit row wrapping. Beyond that, the call to `FunctionCodeGenerator.generateFunction` will ask for a `AsyncFunction`, similar to async calcs.

#### Requirement Summary
This section specifies two code generation changes: (1) extending `DelegatingResultFuture` to handle implicit Row wrapping for async table function results, and (2) generating `AsyncFunction` wrappers from `FunctionCodeGenerator.generateFunction` for async correlate calls, similar to how async calcs work. The PR implements `AsyncCorrelateCodeGenerator` for the code generation pipeline, extends `DelegatingAsyncResultFuture` with Row wrapping support, and adds `DelegatingAsyncTableResultFuture` for the table-specific future handling. It also updates `BridgingFunctionGenUtil` to support code generation for async table function calls.

**File proportion:** 3/67 files mapped (4.5%) + 1/67 files associated (1.5%) = 4/67 accounted (6.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGenerator.java` | Added | +106 / -0 | `AsyncCorrelateCodeGenerator`, `AsyncCorrelateFunctionsValidator` | `AsyncCorrelateCodeGenerator.generateFunction`, `AsyncCorrelateCodeGenerator.getFunctionClass`, `AsyncCorrelateCodeGenerator.generateProcessCode`, `AsyncCorrelateFunctionsValidator.AsyncCorrelateFunctionsValidator`, `AsyncCorrelateFunctionsValidator.visitCall` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/DelegatingAsyncTableResultFuture.java` | Renamed | +38 / -8 | `DelegatingAsyncTableResultFuture` | `DelegatingAsyncTableResultFuture.DelegatingAsyncTableResultFuture`, `DelegatingAsyncTableResultFuture.accept`, `DelegatingAsyncTableResultFuture.wrapInternal`, `DelegatingAsyncTableResultFuture.wrapExternal`, `DelegatingAsyncTableResultFuture.getCompletableFuture` |
| `flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/codegen/calls/BridgingFunctionGenUtil.scala` | Modified | +32 / -20 | `BridgingFunctionGenUtil` | `BridgingFunctionGenUtil.generateFunctionAwareCall`, `BridgingFunctionGenUtil.generateAsyncTableFunctionCall`, `BridgingFunctionGenUtil.verifyFunctionAwareOutputType` |

#### Modification Summary
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGenerator.java`**: Adds the new `AsyncCorrelateCodeGenerator` that generates `AsyncFunction` wrappers from async table function calls, producing code that invokes `FunctionCodeGenerator.generateFunction` to create the async function, as specified in the requirement.
- **`flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/DelegatingAsyncTableResultFuture.java`**: Extends `DelegatingResultFuture` to handle implicit Row wrapping for async table function results, as specified in the requirement. Wraps non-Row single-field results into a Row automatically.
- **`flink-table/flink-table-planner/src/main/scala/org/apache/flink/table/planner/codegen/calls/BridgingFunctionGenUtil.scala`**: Updated to support code generation for async table function calls, adding the bridging logic needed to generate `AsyncFunction` wrappers from `AsyncTableFunction` eval methods.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/calc/async/DelegatingAsyncResultFuture.java` | Modified | +2 / -1 | Patch only updates a Javadoc reference following the introduction of `DelegatingAsyncTableResultFuture`; no functional code generation behavior is added here | — | — |

---

## Section 11: Operator
*Path: Proposed Changes > Runtime Changes > Operator*
*Classification: Implementable*

> Since the call to the `AsyncTableFunction` is wrapped in a `AsyncFunction` taking input rows, we have the benefit of using the existing `AsyncWaitOperator`, which handles ordering, checkpointing, timeouts and other implementation details. Since only ordered results are handled in this scope, `ORDERED` will be the behavior.

#### Requirement Summary
This section specifies that the async correlate operator reuses the existing `AsyncWaitOperator` infrastructure by wrapping the `AsyncTableFunction` call in an `AsyncFunction`. The operator uses `ORDERED` output mode. The PR implements `CommonExecAsyncCorrelate` and `StreamExecAsyncCorrelate` exec nodes that construct an `AsyncWaitOperator` with ordered behavior, creates `AsyncCorrelateRunner` as the `AsyncFunction` implementation, and extracts shared async utility methods into `AsyncUtil` (refactored from `AsyncScalarUtil`).

**File proportion:** 5/67 files mapped (7.5%) + 3/67 files associated (4.5%) = 8/67 accounted (11.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/common/CommonExecAsyncCorrelate.java` | Added | +155 / -0 | `CommonExecAsyncCorrelate` | `CommonExecAsyncCorrelate.CommonExecAsyncCorrelate`, `CommonExecAsyncCorrelate.translateToPlanInternal`, `CommonExecAsyncCorrelate.createAsyncOneInputTransformation`, `CommonExecAsyncCorrelate.getAsyncFunctionOperator`, `CommonExecAsyncCorrelate.cast` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/stream/StreamExecAsyncCorrelate.java` | Added | +93 / -0 | `StreamExecAsyncCorrelate` | `StreamExecAsyncCorrelate.StreamExecAsyncCorrelate` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/AsyncCorrelateRunner.java` | Added | +159 / -0 | `AsyncCorrelateRunner`, `JoinedRowResultFuture` | `AsyncCorrelateRunner.AsyncCorrelateRunner`, `AsyncCorrelateRunner.open`, `AsyncCorrelateRunner.asyncInvoke`, `AsyncCorrelateRunner.close`, `JoinedRowResultFuture.JoinedRowResultFuture`, `JoinedRowResultFuture.complete`, `JoinedRowResultFuture.completeResultFuture`, `JoinedRowResultFuture.wrapPrimitivesAndConvert`, `JoinedRowResultFuture.completeExceptionally`, `JoinedRowResultFuture.close` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncTableUtil.java` | Added | +67 / -0 | `AsyncTableUtil` | `AsyncTableUtil.getAsyncOptions`, `AsyncTableUtil.getResultRetryStrategy` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncUtil.java` | Added | +190 / -0 | `AsyncUtil`, `FunctionFinder`, `AsyncRemoteCallFinder` | `AsyncUtil.containsAsyncCall`, `AsyncUtil.containsNonAsyncCall`, `AsyncUtil.isAsyncCall`, `AsyncUtil.isNonAsyncCall`, `FunctionFinder.FunctionFinder`, `FunctionFinder.visitNode`, `FunctionFinder.isImmediateAsyncCall`, `FunctionFinder.visitCall`, `AsyncRemoteCallFinder.AsyncRemoteCallFinder`, `AsyncRemoteCallFinder.containsRemoteCall`, `AsyncRemoteCallFinder.containsNonRemoteCall`, `AsyncRemoteCallFinder.isRemoteCall`, `AsyncRemoteCallFinder.isNonRemoteCall`, `AsyncRemoteCallFinder.getName`, `AsyncRemoteCallFinder.equals`, `AsyncRemoteCallFinder.hashCode` |

#### Modification Summary
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/common/CommonExecAsyncCorrelate.java`**: Adds the `CommonExecAsyncCorrelate` exec node that constructs an `AsyncWaitOperator` with `ORDERED` output mode, implementing the operator reuse strategy described in the requirement. Wires the generated `AsyncFunction` to the operator with timeout and retry configuration.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/nodes/exec/stream/StreamExecAsyncCorrelate.java`**: Adds the streaming-specific `StreamExecAsyncCorrelate` that extends `CommonExecAsyncCorrelate` with stream exec node metadata and serialization support.
- **`flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/correlate/async/AsyncCorrelateRunner.java`**: Implements the `AsyncFunction` that wraps `AsyncTableFunction` calls, taking input rows and producing output rows through the `AsyncWaitOperator` infrastructure as specified.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncTableUtil.java`**: Adds utility methods for reading async table configuration options and constructing async correlate operators.
- **`flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncUtil.java`**: Extracts shared async utility methods (previously in `AsyncScalarUtil`) into a common utility class used by both async calcs and async correlates.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/AsyncScalarUtil.java` | Modified | +0 / -75 | Methods moved to shared AsyncUtil class during refactoring | `AsyncScalarUtil`, `FunctionFinder` | `AsyncScalarUtil.containsAsyncCall`, `AsyncScalarUtil.containsNonAsyncCall`, `AsyncScalarUtil.isAsyncCall`, `AsyncScalarUtil.isNonAsyncCall`, `FunctionFinder.FunctionFinder`, `FunctionFinder.visitNode`, `FunctionFinder.isImmediateAsyncCall`, `FunctionFinder.visitCall` |
| `flink-table/flink-table-planner/src/main/java/org/apache/flink/table/planner/plan/utils/ExecNodeMetadataUtil.java` | Modified | +2 / -0 | Registers new StreamExecAsyncCorrelate in the exec node metadata registry | `ExecNodeMetadataUtil` | — |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/calc/async/AsyncFunctionRunner.java` | Modified | +1 / -1 | Updated to align with refactored async function runner interface shared with AsyncCorrelateRunner | `AsyncFunctionRunner` | — |

---

## Section 13: Test Plan
*Classification: Implementable*

>   * Unit tests on all of the components
>
>   * Test cases that cover:
>
>     * The split rule
>
>     * ITCases with a bunch of correlate queries
>
>       * Single non-Row return value
>
>       * Hint with Row return value
>
>       * operand calc to table function input
>
>       * Async operand calc to table function input
>
>       * SELECT projections in inner correlate query (not supported)
>
>       * WHERE conditions in inner correlate query (not supported)

#### Requirement Summary
This section specifies the test plan for the implementation: unit tests for all components, split rule tests, and integration test cases covering various correlate query scenarios (single non-Row return value, hint with Row return value, operand calcs, async operand calcs, unsupported SELECT projections and WHERE conditions). The PR implements comprehensive test coverage including `AsyncCorrelateCodeGeneratorTest`, `AsyncCorrelateSplitRuleTest`, `AsyncCorrelateITCase` (integration tests with all specified scenarios), `AsyncUtilTest`, `AsyncCorrelateRestoreTest` (state restore tests), and supporting test utilities and test data fixtures.

**File proportion:** 10/67 files mapped (14.9%) + 16/67 files associated (23.9%) = 26/67 accounted (38.8%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/test/java/org/apache/flink/api/java/typeutils/TypeExtractionUtilsTest.java` | Added | +74 / -0 | — | — |
| `flink-table/flink-table-common/src/test/java/org/apache/flink/table/functions/UserDefinedFunctionHelperTest.java` | Modified | +69 / -0 | — | — |
| `flink-table/flink-table-common/src/test/java/org/apache/flink/table/types/extraction/TypeInferenceExtractorTest.java` | Modified | +159 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGeneratorTest.java` | Added | +298 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRuleTest.java` | Modified | +42 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/runtime/stream/table/AsyncCorrelateITCase.java` | Added | +384 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/utils/AsyncUtilTest.java` | Added | +163 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/nodes/exec/stream/AsyncCorrelateRestoreTest.java` | Added | +43 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRuleTest.java` | Modified | +6 / -0 | — | — |
| `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/aggregate/correlate/AsyncCorrelateRunnerTest.java` | Added | +195 / -0 | — | — |

#### Modification Summary
- **`flink-core/src/test/java/org/apache/flink/api/java/typeutils/TypeExtractionUtilsTest.java`**: Tests the new `TypeExtractionUtils` methods that resolve `eval` methods on `AsyncTableFunction` subclasses.
- **`flink-table/flink-table-common/src/test/java/org/apache/flink/table/functions/UserDefinedFunctionHelperTest.java`**: Validates that the UDF helper recognizes `AsyncTableFunction` as a valid correlate function type.
- **`flink-table/flink-table-common/src/test/java/org/apache/flink/table/types/extraction/TypeInferenceExtractorTest.java`**: Validates type inference extraction for `AsyncTableFunction` eval methods, including `CompletableFuture` return types and implicit Row wrapping.
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/codegen/AsyncCorrelateCodeGeneratorTest.java`**: Unit tests for the async correlate code generation component.
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRuleTest.java`**: Tests for the async correlate split rule.
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/runtime/stream/table/AsyncCorrelateITCase.java`**: Integration test cases covering correlate queries with all specified scenarios (single non-Row return, hint with Row return, operand calc to TF input, async operand calc, unsupported SELECT/WHERE inside correlate).
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/utils/AsyncUtilTest.java`**: Unit tests for the shared async utility helpers.
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/nodes/exec/stream/AsyncCorrelateRestoreTest.java`**: State-restore tests validating plan compatibility for the async correlate operator.
- **`flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRuleTest.java`**: Updated async calc split rule tests after the shared-rule refactor.
- **`flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/aggregate/correlate/AsyncCorrelateRunnerTest.java`**: Unit tests for the AsyncCorrelateRunner operator component.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/plan/nodes/exec/stream/AsyncCorrelateTestPrograms.java` | Added | +238 / -0 | Test program definitions consumed as fixtures by `AsyncCorrelateRestoreTest`; supports the restore-test cases rather than being a direct unit/IT test | — | — |
| `flink-table/flink-table-planner/src/test/java/org/apache/flink/table/planner/runtime/utils/JavaUserDefinedTableFunctions.java` | Modified | +77 / -0 | Test utility class providing Java async table function implementations used by IT cases; supporting test helper, not a direct test case | — | — |
| `flink-table/flink-table-planner/src/test/resources/org/apache/flink/table/planner/plan/rules/logical/AsyncCalcSplitRuleTest.xml` | Modified | +18 / -0 | Expected-plan fixture consumed by `AsyncCalcSplitRuleTest`; test data, not a test case | — | — |
| `flink-table/flink-table-planner/src/test/resources/org/apache/flink/table/planner/plan/rules/logical/AsyncCorrelateSplitRuleTest.xml` | Modified | +68 / -1 | Expected-plan fixture consumed by `AsyncCorrelateSplitRuleTest`; test data, not a test case | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-catalog-func/plan/async-correlate-catalog-func.json` | Added | +140 / -0 | Restore-test plan fixture data for the catalog-function scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-catalog-func/savepoint/_metadata` | Added | +0 / -0 | Restore-test savepoint fixture data for the catalog-function scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-exception/plan/async-correlate-exception.json` | Added | +140 / -0 | Restore-test plan fixture data for the exception scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-exception/savepoint/_metadata` | Added | +0 / -0 | Restore-test savepoint fixture data for the exception scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-join-filter/plan/async-correlate-join-filter.json` | Added | +207 / -0 | Restore-test plan fixture data for the join-filter scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-join-filter/savepoint/_metadata` | Added | +0 / -0 | Restore-test savepoint fixture data for the join-filter scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-left-join/plan/async-correlate-left-join.json` | Added | +136 / -0 | Restore-test plan fixture data for the left-join scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-left-join/savepoint/_metadata` | Added | +0 / -0 | Restore-test savepoint fixture data for the left-join scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-system-func/plan/async-correlate-system-func.json` | Added | +140 / -0 | Restore-test plan fixture data for the system-function scenario | — | — |
| `flink-table/flink-table-planner/src/test/resources/restore-tests/stream-exec-correlate_1/async-correlate-system-func/savepoint/_metadata` | Added | +0 / -0 | Restore-test savepoint fixture data for the system-function scenario | — | — |
| `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/plan/stream/sql/join/LookupJoinTest.scala` | Modified | +16 / -15 | Lookup-join regression test adapted for the refactored async function infrastructure; supports the refactor rather than being a direct async-correlate test case | — | — |
| `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/plan/utils/lookupFunctions.scala` | Modified | +6 / -1 | Test utility functions updated for refactored async table function handling; supporting test helper | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

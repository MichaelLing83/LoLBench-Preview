# Apache Flink - FLIP-467: Introduce Generalized Watermarks

**PR:** https://github.com/apache/flink/pull/25731
**Requirement Doc:** https://cwiki.apache.org/confluence/display/FLINK/FLIP-467

## Matching Statistics
- **Requirement Doc Coverage:** 11/11 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 71/136 files mapped (52.2%) + 65/136 files associated (47.8%) = 136/136 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | FLIP-467: Introduce Generalized Watermarks | No | N/A | knowledge |
| 2 | Background | No | N/A | contextual |
| 3 | Example: | No | N/A | knowledge |
| 4 | Proposed Changes | No | N/A | knowledge |
| 5 | Proposed Changes > Watermark Definition | Yes | Yes | implementation |
| 6 | Proposed Changes > Declare Watermark | Yes | Yes | implementation |
| 7 | Proposed Changes > Emit Watermark | No | N/A | knowledge |
| 8 | Proposed Changes > Emit Watermark > Emit watermark from process function | Yes | Yes | implementation |
| 9 | Proposed Changes > Emit Watermark > Emit watermark from source | Yes | Yes | implementation |
| 10 | Proposed Changes > Combine Watermarks | Yes | Yes | implementation |
| 11 | Proposed Changes > Handle Watermarks in Process Function | Yes | Yes | implementation |
| 12 | Proposed Changes > Handle Watermarks in Process Function > OneInputStreamProcessFunction | Yes | Yes | implementation |
| 13 | Proposed Changes > Handle Watermarks in Process Function > TwoInputBroadcastStreamProcessFunction | Yes | Yes | implementation |
| 14 | Proposed Changes > Handle Watermarks in Process Function > TwoInputNonBroadcastStreamProcessFunction | Yes | Yes | implementation |
| 15 | Proposed Changes > Handle Watermarks in Process Function > TwoOutputStreamProcessFunction | Yes | Yes | implementation |
| 16 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 17 | Test Plan | Yes | Yes | evaluation |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `flink-architecture-tests/flink-architecture-tests-production/archunit-violations/18509c9e-3250-4c52-91b9-11ccefc85db1` | test-data | — | Section 5 |
| 2 | `flink-architecture-tests/flink-architecture-tests-production/archunit-violations/e5126cae-f3fe-48aa-b6fb-60ae6cc3fcd5` | test-data | — | Section 5 |
| 3 | `flink-connectors/flink-connector-base/src/test/java/org/apache/flink/connector/base/source/reader/SourceReaderBaseTest.java` | test | Section 17 | — |
| 4 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermark.java` | source | Section 5 | — |
| 5 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermarkDeclaration.java` | source | Section 6 | — |
| 6 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermark.java` | source | Section 5 | — |
| 7 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermarkDeclaration.java` | source | Section 6 | — |
| 8 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/Watermark.java` | source | Section 5 | — |
| 9 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationFunction.java` | source | Section 10 | — |
| 10 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationPolicy.java` | source | Section 10 | — |
| 11 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclaration.java` | source | Section 6 | — |
| 12 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclarations.java` | source | Section 6 | — |
| 13 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingResult.java` | source | Section 11 | — |
| 14 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingStrategy.java` | source | Section 11 | — |
| 15 | `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkManager.java` | source | Section 8 | — |
| 16 | `flink-core-api/src/test/java/org/apache/flink/api/common/watermark/WatermarkDeclarationsTest.java` | test | Section 17 | — |
| 17 | `flink-core/src/main/java/org/apache/flink/api/connector/source/Source.java` | source | Section 6 | — |
| 18 | `flink-core/src/main/java/org/apache/flink/api/connector/source/SourceReaderContext.java` | source | Section 9 | — |
| 19 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/BasePartitionedContext.java` | source | — | Section 8 |
| 20 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/NonPartitionedContext.java` | source | Section 8 | — |
| 21 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/PartitionedContext.java` | source | Section 8 | — |
| 22 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputNonPartitionedContext.java` | source | Section 8 | — |
| 23 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputPartitionedContext.java` | source | Section 8 | — |
| 24 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/OneInputStreamProcessFunction.java` | source | Section 12 | — |
| 25 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/ProcessFunction.java` | source | — | Section 6 |
| 26 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputBroadcastStreamProcessFunction.java` | source | Section 13 | — |
| 27 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputNonBroadcastStreamProcessFunction.java` | source | Section 14 | — |
| 28 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputApplyPartitionFunction.java` | source | — | Section 15 |
| 29 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputStreamProcessFunction.java` | source | Section 15 | — |
| 30 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/ExecutionEnvironmentImpl.java` | source | — | Section 6 |
| 31 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/AbstractPartitionedContext.java` | source | — | Section 8 |
| 32 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContext.java` | source | — | Section 8 |
| 33 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultPartitionedContext.java` | source | — | Section 8 |
| 34 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContext.java` | source | — | Section 8 |
| 35 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputPartitionedContext.java` | source | — | Section 8 |
| 36 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | source | — | Section 12 |
| 37 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java` | source | — | Section 13 |
| 38 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | source | — | Section 14 |
| 39 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | source | — | Section 15 |
| 40 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | source | — | Section 12 |
| 41 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java` | source | — | Section 13 |
| 42 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java` | source | — | Section 14 |
| 43 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java` | source | — | Section 15 |
| 44 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/watermark/DefaultWatermarkManager.java` | source | Section 8 | — |
| 45 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/attribute/StreamingJobGraphGeneratorWithAttributeTest.java` | test | Section 17 | — |
| 46 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContextTest.java` | test | Section 17 | — |
| 47 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContextTest.java` | test | Section 17 | — |
| 48 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/functions/ProcessFunctionTest.java` | test | Section 17 | — |
| 49 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperatorTest.java` | test | Section 17 | — |
| 50 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperatorTest.java` | test | Section 17 | — |
| 51 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/stream/StreamTestUtils.java` | test | Section 17 | — |
| 52 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/StreamUtilsTest.java` | test | Section 17 | — |
| 53 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/WatermarkUtilsTest.java` | test | Section 17 | — |
| 54 | `flink-datastream/src/test/resources/log4j2-test.properties` | test-data | Section 17 | — |
| 55 | `flink-libraries/flink-state-processing-api/src/main/java/org/apache/flink/state/api/output/operators/StateBootstrapWrapperOperator.java` | source | — | Section 11 |
| 56 | `flink-libraries/flink-state-processing-api/src/main/java/org/apache/flink/state/api/output/operators/StateBootstrapWrapperOperatorFactory.java` | source | — | Section 11 |
| 57 | `flink-runtime/pom.xml` | build | — | Section 10 |
| 58 | `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/AbstractAsyncStateStreamOperator.java` | source | — | Section 11 |
| 59 | `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/TimestampedCollectorWithDeclaredVariable.java` | source | — | Section 11 |
| 60 | `flink-runtime/src/main/java/org/apache/flink/runtime/event/WatermarkEvent.java` | source | — | Section 5 |
| 61 | `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializer.java` | source | — | Section 5 |
| 62 | `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/buffer/Buffer.java` | source | — | Section 5 |
| 63 | `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/InputGate.java` | source | — | Section 10 |
| 64 | `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/SingleInputGate.java` | source | — | Section 10 |
| 65 | `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/UnionInputGate.java` | source | — | Section 10 |
| 66 | `flink-runtime/src/main/java/org/apache/flink/runtime/taskmanager/InputGateWithMetrics.java` | source | — | Section 10 |
| 67 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamConfig.java` | source | Section 6 | — |
| 68 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraph.java` | source | — | Section 6 |
| 69 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java` | source | — | Section 6 |
| 70 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamNode.java` | source | — | Section 6 |
| 71 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamingJobGraphGenerator.java` | source | — | Section 6 |
| 72 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/AbstractStreamOperator.java` | source | — | Section 11 |
| 73 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/CountingOutput.java` | source | — | Section 11 |
| 74 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/Input.java` | source | Section 11 | — |
| 75 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/KeyedProcessOperator.java` | source | — | Section 12 |
| 76 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/Output.java` | source | — | Section 11 |
| 77 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperator.java` | source | Section 9 | — |
| 78 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperatorFactory.java` | source | Section 9 | — |
| 79 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/TimestampedCollector.java` | source | — | Section 11 |
| 80 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/TwoInputStreamOperator.java` | source | — | Section 13 |
| 81 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/MultiInputSortingDataInput.java` | source | — | Section 10 |
| 82 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/SortingDataInput.java` | source | — | Section 10 |
| 83 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java` | source | Section 10 | — |
| 84 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/FinishedDataOutput.java` | source | — | Section 11 |
| 85 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/PushingAsyncDataInput.java` | source | — | Section 11 |
| 86 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/RecordWriterOutput.java` | source | — | Section 11 |
| 87 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamMultipleInputProcessorFactory.java` | source | — | Section 10 |
| 88 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInput.java` | source | Section 10 | — |
| 89 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputFactory.java` | source | — | Section 10 |
| 90 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTwoInputProcessorFactory.java` | source | — | Section 10 |
| 91 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/checkpointing/CheckpointedInputGate.java` | source | — | Section 10 |
| 92 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/recovery/RescalingStreamTaskNetworkInput.java` | source | — | Section 10 |
| 93 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/BroadcastingOutputCollector.java` | source | — | Section 11 |
| 94 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/ChainingOutput.java` | source | — | Section 11 |
| 95 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/FinishedOnRestoreMainOperatorOutput.java` | source | — | Section 11 |
| 96 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/OneInputStreamTask.java` | source | — | Section 10 |
| 97 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/SourceOperatorStreamTask.java` | source | — | Section 9 |
| 98 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/StreamIterationTail.java` | source | — | Section 11 |
| 99 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AbstractInternalWatermarkDeclaration.java` | source | Section 10 | — |
| 100 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/Alignable.java` | source | Section 10 | — |
| 101 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableBoolWatermarkDeclaration.java` | source | Section 10 | — |
| 102 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableLongWatermarkDeclaration.java` | source | Section 10 | — |
| 103 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignedWatermarkCombiner.java` | source | Section 10 | — |
| 104 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/BoolWatermarkCombiner.java` | source | Section 10 | — |
| 105 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalBoolWatermarkDeclaration.java` | source | Section 10 | — |
| 106 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalLongWatermarkDeclaration.java` | source | Section 10 | — |
| 107 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/LongWatermarkCombiner.java` | source | Section 10 | — |
| 108 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/WatermarkCombiner.java` | source | Section 10 | — |
| 109 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermarkstatus/HeapPriorityQueue.java` | source | — | Section 10 |
| 110 | `flink-runtime/src/main/java/org/apache/flink/streaming/util/watermark/WatermarkUtils.java` | source | — | Section 6 |
| 111 | `flink-runtime/src/test/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializerTest.java` | test | Section 17 | — |
| 112 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/SourceOperatorTest.java` | test | Section 17 | — |
| 113 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/CollectingDataOutput.java` | test | Section 17 | — |
| 114 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/LargeSortingDataInputITCase.java` | test | Section 17 | — |
| 115 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/CollectingDataOutput.java` | test | Section 17 | — |
| 116 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/TestingSourceOperator.java` | test | Section 17 | — |
| 117 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/watermark/generalized/WatermarkCombinerTest.java` | test | Section 17 | — |
| 118 | `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockIndexedInputGate.java` | test | Section 17 | — |
| 119 | `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockInputGate.java` | test | Section 17 | — |
| 120 | `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/checkpointing/AlignedCheckpointsMassiveRandomTest.java` | test | Section 17 | — |
| 121 | `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/watermarkstatus/StatusWatermarkValveTest.java` | test | Section 17 | — |
| 122 | `flink-runtime/src/test/java/org/apache/flink/streaming/util/AbstractStreamOperatorTestHarness.java` | test | Section 17 | — |
| 123 | `flink-runtime/src/test/java/org/apache/flink/streaming/util/CollectorOutput.java` | test | Section 17 | — |
| 124 | `flink-runtime/src/test/java/org/apache/flink/streaming/util/MockOutput.java` | test | Section 17 | — |
| 125 | `flink-runtime/src/test/java/org/apache/flink/streaming/util/SourceOperatorTestHarness.java` | test | Section 17 | — |
| 126 | `flink-streaming-java/src/test/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputTest.java` | test | Section 17 | — |
| 127 | `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/runtime/utils/TimeTestUtil.scala` | test | Section 17 | — |
| 128 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/BroadcastingOutput.java` | source | — | Section 11 |
| 129 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/CopyingSecondInputOfTwoInputStreamOperatorOutput.java` | source | — | Section 11 |
| 130 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/FirstInputOfTwoInputStreamOperatorOutput.java` | source | — | Section 11 |
| 131 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/OneInputStreamOperatorOutput.java` | source | — | Section 11 |
| 132 | `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/SecondInputOfTwoInputStreamOperatorOutput.java` | source | — | Section 11 |
| 133 | `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/multipleinput/output/BlackHoleOutput.java` | test | Section 17 | — |
| 134 | `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/over/NonBufferOverWindowOperatorTest.java` | test | Section 17 | — |
| 135 | `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/WatermarkITCase.java` | test | Section 17 | — |
| 136 | `pom.xml` | build | — | Section 10 |

---

## Section 5: Watermark Definition
*Path: Proposed Changes > Watermark Definition*
*Classification: Implementable*

> First of all, let's define the _**watermark**_.
>
> (Note: The _**watermark**_ in the subsequent content refers to the generalized watermark proposed in this FLIP)
>
> ```java
> /* * This interface represents a watermark. It will provide a unified triggering and
>  * alignment mechanism for user-defined event-like things.
>  */
> @Experimental
> public interface Watermark extends Serializable {
>     /**
>      * Returns the unique identifier for this watermark.
>      *
>      * @return a {@code String} representing the unique identifier of the watermark
>      */
>     String getIdentifier();
> }
> ```
>
> The identifiers for watermarks are case-sensitive and must be globally unique throughout the entire job. To prevent identifier duplication, the Flink internal watermark identifiers and the identifiers developed for connectors can be prefixed with the name of their respective module or connector. For example, they could be named "INTERNAL_RUNTIME_BACKLOG" or "CONNECTOR_KAFKA_IDLE."
>
> We currently only expose the following two types of _**Watermark**_ to users (which is enough to meet our known requirements for generalized watermark), but if we see more requirements in the future, we can consider letting users customize watermark(i.e. allow them to implement Watermark interface themselves).
>
> ```java
> /**
>  * The {@link LongWatermark}  represents a watermark with a long value and
>  * an associated identifier.
>  */
> @Experimental
> public class LongWatermark implements Watermark {
>     private static final long serialVersionUID = 1L;
>     private final long value;
>     private final String identifier;
>
>     public LongWatermark(long value, String identifier) {
>         this.value = value;
>         this.identifier = identifier;
>     }
>
>     public long getValue() {
>         return value;
>     }
>
>     @Override
>     public String getIdentifier() {
>         return identifier;
>     }
> }
> ```
>
> ```java
> /**
>  * The {@link BoolWatermark} represents a watermark with a boolean value and an
>  * associated identifier.
>  */
> @Experimental
> public class BoolWatermark implements Watermark {
>     private static final long serialVersionUID = 1L;
>     private final boolean value;
>     private final String identifier;
>
>     public BoolWatermark(boolean value, String identifier) {
>         this.value = value;
>         this.identifier = identifier;
>     }
>
>     public boolean getValue() {
>         return value;
>     }
>
>     @Override
>     public String getIdentifier() {
>         return identifier;
>     }
> }
> ```
>
> Note that the new _**`Watermark`**_ is completely decoupled from any watermark/marker-specific (e.g., time-specific) semantics. 

#### Requirement Summary
This section specifies the base `Watermark` interface and its two concrete types: `BoolWatermark` and `LongWatermark`. The PR implements these as new classes in `flink-core-api` along with the runtime `WatermarkEvent` serialization wrapper.

**File proportion:** 3/136 files mapped (2.2%) + 5/136 files associated (3.7%) = 8/136 accounted (5.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/Watermark.java` | Added | +34 / -0 | `Watermark` | `Watermark.getIdentifier` |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermark.java` | Added | +73 / -0 | `BoolWatermark` | `BoolWatermark.BoolWatermark`, `BoolWatermark.getValue`, `BoolWatermark.getIdentifier`, `BoolWatermark.equals`, `BoolWatermark.hashCode`, `BoolWatermark.toString` |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermark.java` | Added | +72 / -0 | `LongWatermark` | `LongWatermark.LongWatermark`, `LongWatermark.getValue`, `LongWatermark.getIdentifier`, `LongWatermark.equals`, `LongWatermark.hashCode`, `LongWatermark.toString` |

#### Modification Summary
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/Watermark.java`**: Defines the base `Watermark` interface with an identifier method, as specified by the FLIP's watermark abstraction.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermark.java`**: Implements the `Watermark` interface for boolean-valued watermarks with an identifier and boolean value, as described in the "two types" part of the section.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermark.java`**: Implements the `Watermark` interface for long-valued watermarks with an identifier and long value, as described in the "two types" part of the section.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-architecture-tests/flink-architecture-tests-production/archunit-violations/18509c9e-3250-4c52-91b9-11ccefc85db1` | Modified | +2 / -0 | Architecture test violation list must be updated when new public API classes are added | — | — |
| `flink-architecture-tests/flink-architecture-tests-production/archunit-violations/e5126cae-f3fe-48aa-b6fb-60ae6cc3fcd5` | Modified | +4 / -4 | Architecture test violation list must be updated when new public API classes are added | — | — |
| `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializer.java` | Modified | +17 / -0 | Serializer must be extended to handle the new WatermarkEvent type | `EventSerializer` | `EventSerializer.toSerializedEvent`, `EventSerializer.fromSerializedEvent` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/buffer/Buffer.java` | Modified | +20 / -1 | Buffer type enum must include the new WatermarkEvent data type | `DataType` | `DataType.getDataType` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/event/WatermarkEvent.java` | Added | +127 / -0 | Runtime event wrapper for serializing and transmitting generalized watermarks through the Flink network stack; supports the watermark propagation described in this section but is not part of the public `Watermark` value API | `WatermarkEvent` | `WatermarkEvent.WatermarkEvent`, `WatermarkEvent.write`, `WatermarkEvent.read`, `WatermarkEvent.getWatermark`, `WatermarkEvent.isAligned`, `WatermarkEvent.equals`, `WatermarkEvent.hashCode`, `WatermarkEvent.toString` |

---

## Section 6: Declare Watermark
*Path: Proposed Changes > Declare Watermark*
*Classification: Implementable*

> Before emitting _**Watermark**_ , you must declare it in advance and define the alignment and propagation semantics.
>
> ```java
> /**
>  * This class represents the watermark creation and handling policy defined by the user.
>  */
> @Experimental
> public interface WatermarkDeclaration extends Serializable {
>     /**
>      * Returns the unique identifier for this watermark.
>      *
>      * @return a {@code String} representing the unique identifier of the watermark
>      */
>     String getIdentifier();
> }
> ```
>
> Since only two types of _**Watermark**_ are provided, their corresponding _**`Declaration`**_ is as follows:
>
> Note: The definition and role of _**`WatermarkCombinationPolicy`**_ and _**`WatermarkHandlingStrategy`**_ , see later in this FLIP.
>
> ```java
> /**
>  * The {@link LongWatermarkDeclaration} class implements the {@link WatermarkDeclaration} interface
>  * and provides additional functionality specific to long-type watermarks. It includes methods for
>  * obtaining combination semantics and creating new long watermarks.
>  */
> @Experimental
> public class LongWatermarkDeclaration implements WatermarkDeclaration {
>
>     private final String identifier;
>
>     private final WatermarkCombinationPolicy combinationPolicy;
>
>     private final WatermarkHandlingStrategy defaultHandlingStrategy;
>
>     public LongWatermarkDeclaration(
>             String identifier,
>             WatermarkCombinationPolicy combinationPolicy,
>             WatermarkHandlingStrategy defaultHandlingStrategy) {
>         this.identifier = identifier;
>         this.combinationPolicy = combinationPolicy;
>         this.defaultHandlingStrategy = defaultHandlingStrategy;
>     }
>
>     @Override
>     public String getIdentifier() {
>         return identifier;
>     }
>
>     public WatermarkCombinationPolicy getCombinationPolicy() {
>         return combinationPolicy;
>     }
>
>     public WatermarkHandlingStrategy getDefaultHandlingStrategy() {
>         return defaultHandlingStrategy;
>     }
>
>     /** Creates a new {@link LongWatermark} with the specified long value. */
>     public LongWatermark newWatermark(long val) {
>         return new LongWatermark(val, identifier);
>     };
> }
> ```
>
> ```java
> /**
>  * The {@link BoolWatermarkDeclaration} class implements the {@link WatermarkDeclaration} interface
>  * and provides additional functionality specific to boolean-type watermarks. It includes methods for
>  * obtaining combination semantics and creating new bool watermarks.
>  */
> @Experimental
> public class BoolWatermarkDeclaration implements WatermarkDeclaration {
>
>     private final String identifier;
>
>     private final WatermarkCombinationPolicy combinationPolicy;
>
>     private final WatermarkHandlingStrategy defaultHandlingStrategy;
>
>     public BoolWatermarkDeclaration(
>             String identifier,
>             WatermarkCombinationPolicy combinationPolicy,
>             WatermarkHandlingStrategy defaultHandlingStrategy) {
>         this.identifier = identifier;
>         this.combinationPolicy = combinationPolicy;
>         this.defaultHandlingStrategy = defaultHandlingStrategy;
>     }
>
>     @Override
>     public String getIdentifier() {
>         return identifier;
>     }
>
>     public WatermarkCombinationPolicy getCombinationPolicy() {
>         return combinationPolicy;
>     }
>
>     public WatermarkHandlingStrategy getDefaultHandlingStrategy() {
>         return defaultHandlingStrategy;
>     }
>
>     /** Creates a new {@link BoolWatermark} with the specified boolean value. */
>     public BoolWatermark newWatermark(boolean val) {
>         return new BoolWatermark(val, identifier);
>     }
> }
> ```
>
> Since only _**Process Function**_ and _**Source**_ can emit _**watermark**_ , the following methods are introduced for each of them to declare watermark.
>
>   1. _**Watermark**_ from _**Process Function**_
>
> ```java
> public interface ProcessFunction extends Function {
>
>   /**
>    * Explicitly declare watermarks upfront. Each specific watermark must be declared in this method
>    * before it can be used.
>    *
>    * @return all watermark declarations used by this application.
>    */
>   default Collection<? extends WatermarkDeclaration> watermarkDeclarations() {
>       return Collections.emptySet();
>   }
> }
> ```
>
>   2.  _**Watermark**_ from _**Source**_
>
> ```java
> public interface Source<T, SplitT extends SourceSplit, EnumChkT>
>         extends SourceReaderFactory<T, SplitT> {
>   /**
>    * Explicitly declare watermarks upfront. Each specific watermark must be declared in this method
>    * before it can be used.
>    *
>    * @return all watermark declarations used by this application.
>    */
>   default Collection<? extends WatermarkDeclaration> watermarkDeclarations() {
>       return Collections.emptySet();
>   }
> }
> ```
>
> To facilitate the creation of _**`WatermarkDeclaration`**_ , we provide the build tool:
>
> ```java
> /** The Utils class is used to create {@link WatermarkDeclaration}. */
> @Experimental
> public class WatermarkDeclarations {
>
>     public static WatermarkBuilder newBuilder(String identifier) {
>         return new WatermarkBuilder(identifier);
>     }
>
>     /** Builder class for {@link WatermarkDeclaration}s. */
>     @Experimental
>     public static class WatermarkBuilder {
>
>         protected final String identifier;
>
>         WatermarkBuilder(String identifier) {
>             this.identifier = identifier;
>         }
>
>         public LongWatermarkBuilder typeLong() {
>             return new LongWatermarkBuilder(identifier);
>         }
>
>         public BoolWatermarkBuilder typeBool() {
>             return new BoolWatermarkBuilder(identifier);
>         }
>
>         @Experimental
>         public static class LongWatermarkBuilder {
>             private final String identifier;
>             private boolean combineWaitForAllChannels = false;
>             // for channels
>             private WatermarkCombinationFunction combinationFunction =
>                     NumericWatermarkCombinationFunction.MIN;
>             // for function
>             private WatermarkHandlingStrategy defaultHandlingStrategy =
>                     WatermarkHandlingStrategy.FORWARD;
>
>             public LongWatermarkBuilder(String identifier) {
>                 this.identifier = identifier;
>             }
>
>             /** Combine and propagate the maximum watermark to downstream. */
>             public LongWatermarkBuilder combineFunctionMax() {
>                 this.combinationFunction = NumericWatermarkCombinationFunction.MAX;
>                 return this;
>             }
>
>             /** Combine and propagate the minimum watermark to downstream. */
>             public LongWatermarkBuilder combineFunctionMin() {
>                 this.combinationFunction = NumericWatermarkCombinationFunction.MIN;
>                 return this;
>             }
>
>             public LongWatermarkBuilder defaultHandlingStrategyForward() {
>                 this.defaultHandlingStrategy = WatermarkHandlingStrategy.FORWARD;
>                 return this;
>             }
>
>             public LongWatermarkBuilder defaultHandlingStrategyIgnore() {
>                 this.defaultHandlingStrategy = WatermarkHandlingStrategy.IGNORE;
>                 return this;
>             }
>
>             /**
>              * Whether the combine process should be executed after the process function receives
>              * watermarks from both upstream channels.
>              */
>             public LongWatermarkBuilder combineWaitForAllChannels(
>                     boolean combineWaitForAllChannels) {
>                 this.combineWaitForAllChannels = combineWaitForAllChannels;
>                 return this;
>             }
>
>             public LongWatermarkDeclaration build() {
>                 return new LongWatermarkDeclaration(
>                         identifier,
>                         new WatermarkCombinationPolicy(
>                                 this.combinationFunction, this.combineWaitForAllChannels),
>                         this.defaultHandlingStrategy);
>             }
>         }
>
>         @Experimental
>         public static class BoolWatermarkBuilder {
>             private final String identifier;
>             private boolean combineWaitForAllChannels = false;
>             // for channels
>             private WatermarkCombinationFunction combinationFunction =
>                     BoolWatermarkCombinationFunction.AND;
>             // for function
>             private WatermarkHandlingStrategy defaultHandlingStrategy =
>                     WatermarkHandlingStrategy.FORWARD;
>
>             public BoolWatermarkBuilder(String identifier) {
>                 this.identifier = identifier;
>             }
>
>             /** Propagate the logical OR combination result of boolean watermarks downstream. */
>             public BoolWatermarkBuilder combineFunctionOR() {
>                 this.combinationFunction = BoolWatermarkCombinationFunction.OR;
>                 return this;
>             }
>
>             /** Propagate the logical AND combination result of boolean watermarks downstream. */
>             public BoolWatermarkBuilder combineFunctionAND() {
>                 this.combinationFunction = BoolWatermarkCombinationFunction.AND;
>                 return this;
>             }
>
>             public BoolWatermarkBuilder defaultHandlingStrategyForward() {
>                 this.defaultHandlingStrategy = WatermarkHandlingStrategy.FORWARD;
>                 return this;
>             }
>
>             public BoolWatermarkBuilder defaultHandlingStrategyIgnore() {
>                 this.defaultHandlingStrategy = WatermarkHandlingStrategy.IGNORE;
>                 return this;
>             }
>
>             /**
>              * Whether the combine process should be executed after the process function receives
>              * watermarks from both upstream channels.
>              */
>             public BoolWatermarkBuilder combineWaitForAllChannels(
>                     boolean combineWaitForAllChannels) {
>                 this.combineWaitForAllChannels = combineWaitForAllChannels;
>                 return this;
>             }
>
>             public BoolWatermarkDeclaration build() {
>                 return new BoolWatermarkDeclaration(
>                         identifier,
>                         new WatermarkCombinationPolicy(
>                                 this.combinationFunction, this.combineWaitForAllChannels),
>                         this.defaultHandlingStrategy);
>             }
>         }
>     }
> }
> ```

#### Requirement Summary
This section specifies the `WatermarkDeclaration` interface, `BoolWatermarkDeclaration`, `LongWatermarkDeclaration`, the `WatermarkDeclarations` builder utility, and the declaration methods on `ProcessFunction` and `Source`. The PR implements these API classes and integrates declarations into the stream graph configuration.

**File proportion:** 6/136 files mapped (4.4%) + 7/136 files associated (5.1%) = 13/136 accounted (9.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclaration.java` | Added | +34 / -0 | `WatermarkDeclaration` | `WatermarkDeclaration.getIdentifier` |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermarkDeclaration.java` | Added | +97 / -0 | `BoolWatermarkDeclaration` | `BoolWatermarkDeclaration.BoolWatermarkDeclaration`, `BoolWatermarkDeclaration.getIdentifier`, `BoolWatermarkDeclaration.newWatermark`, `BoolWatermarkDeclaration.getCombinationPolicy`, `BoolWatermarkDeclaration.getDefaultHandlingStrategy`, `BoolWatermarkDeclaration.equals`, `BoolWatermarkDeclaration.hashCode`, `BoolWatermarkDeclaration.toString` |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermarkDeclaration.java` | Added | +99 / -0 | `LongWatermarkDeclaration` | `LongWatermarkDeclaration.LongWatermarkDeclaration`, `LongWatermarkDeclaration.getIdentifier`, `LongWatermarkDeclaration.newWatermark`, `LongWatermarkDeclaration.getCombinationPolicy`, `LongWatermarkDeclaration.getDefaultHandlingStrategy`, `LongWatermarkDeclaration.equals`, `LongWatermarkDeclaration.hashCode`, `LongWatermarkDeclaration.toString` |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclarations.java` | Added | +185 / -0 | `WatermarkDeclarations`, `WatermarkDeclarationBuilder`, `LongWatermarkDeclarationBuilder`, `BoolWatermarkDeclarationBuilder` | `WatermarkDeclarations.newBuilder`, `WatermarkDeclarationBuilder.WatermarkDeclarationBuilder`, `WatermarkDeclarationBuilder.typeLong`, `WatermarkDeclarationBuilder.typeBool`, `LongWatermarkDeclarationBuilder.LongWatermarkDeclarationBuilder`, `LongWatermarkDeclarationBuilder.combineFunctionMax`, `LongWatermarkDeclarationBuilder.combineFunctionMin`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategy`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategyForward`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategyIgnore`, `LongWatermarkDeclarationBuilder.combineWaitForAllChannels`, `LongWatermarkDeclarationBuilder.build`, `BoolWatermarkDeclarationBuilder.BoolWatermarkDeclarationBuilder`, `BoolWatermarkDeclarationBuilder.combineFunctionOR`, `BoolWatermarkDeclarationBuilder.combineFunctionAND`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategy`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategyForward`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategyIgnore`, `BoolWatermarkDeclarationBuilder.combineWaitForAllChannels`, `BoolWatermarkDeclarationBuilder.build` |
| `flink-core/src/main/java/org/apache/flink/api/connector/source/Source.java` | Modified | +14 / -0 | `Source` | `Source.declareWatermarks` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamConfig.java` | Modified | +33 / -0 | `StreamConfig` | `StreamConfig.setWatermarkDeclarations`, `StreamConfig.getWatermarkDeclarations` |

#### Modification Summary
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclaration.java`**: Defines the base `WatermarkDeclaration` interface as specified, declaring the contract for watermark declarations.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermarkDeclaration.java`**: Implements the declaration for `BoolWatermark` with combination policy and handling strategy, as specified.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermarkDeclaration.java`**: Implements the declaration for `LongWatermark` with combination policy and handling strategy, as specified.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclarations.java`**: Provides the builder utility for constructing `WatermarkDeclaration` instances, corresponding to the "build tool" described in the section.
- **`flink-core/src/main/java/org/apache/flink/api/connector/source/Source.java`**: Adds the `watermarkDeclarations()` method to the `Source` interface so that sources can declare their watermarks, as specified by "Watermark from Source."
- **`flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamConfig.java`**: Adds configuration keys and methods for serializing/deserializing watermark declarations in the stream graph, enabling the runtime to access declarations at execution time.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/ProcessFunction.java` | Modified | +11 / -0 | `ProcessFunction` must expose the `watermarkDeclarations()` method to declare watermarks from process functions | `ProcessFunction` | `ProcessFunction.declareWatermarks` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/ExecutionEnvironmentImpl.java` | Modified | +1 / -1 | Execution environment wiring must be updated to propagate watermark declarations | `ExecutionEnvironmentImpl` | `ExecutionEnvironmentImpl.fromSource` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraph.java` | Modified | +25 / -0 | Stream graph must store and propagate watermark declarations for each node | `StreamGraph` | `StreamGraph.serializeAndSaveWatermarkDeclarations`, `StreamGraph.getSerializedWatermarkDeclarations` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java` | Modified | +2 / -0 | Stream graph generator must extract watermark declarations during graph construction | `StreamGraphGenerator` | `StreamGraphGenerator.generate` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamNode.java` | Modified | +0 / -1 | Stream node must support watermark declaration fields | `StreamNode` | `StreamNode.getOperator` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamingJobGraphGenerator.java` | Modified | +1 / -0 | Job graph generator must serialize watermark declarations into job vertex config | `StreamingJobGraphGenerator` | `StreamingJobGraphGenerator.createChain` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/util/watermark/WatermarkUtils.java` | Added | +98 / -0 | Utility class for resolving and merging watermark declarations across the stream topology | `WatermarkUtils` | `WatermarkUtils.getInternalWatermarkDeclarationsFromStreamGraph`, `WatermarkUtils.getWatermarkDeclarations`, `WatermarkUtils.convertToInternalWatermarkDeclarations` |

---

## Section 8: Emit watermark from process function
*Path: Proposed Changes > Emit Watermark > Emit watermark from process function*
*Classification: Implementable*

> To emit _**watermark**_ from _**Process Function**_ , we introduce _**`WatermarkManager`**_ interface and add it to _**`NonPartitionedContext`**_.
>
> ```java
> /**
>  * The {@link WatermarkManager} interface provides a mechanism to emit watermarks
>  * from a process function.
>  */
> @Experimental
> public interface WatermarkManager {
>
>     /**
>      * Emits a watermark from the process function.
>      *
>      * @param watermark the {@link GeneralizedWatermark} to emit.
>      */
>     void emitWatermark(Watermark watermark);
> }
> ```
>
> ```java
> @Experimental
> public interface NonPartitionedContext<OUT> extends AbstractPartitionedContext {
>     ...
>
>     /** Get {@link WatermarkManager} instance, which allow emitting a {@link Watermark} from the process function. */
>     WatermarkManager getWatermarkManager();
>
>     ...
> }
> ```
>
> By the way, we also want to add a method for getting _**`NonPartitionedContext`**_ _**from**_ from _**`PartitionedContext`**_. This allow user emit _**watermark**_ in a context with partition.
>
> ```java
> @Experimental
> public interface PartitionedContext extends RuntimeContext {
>     ...
>       /** Get the non-partitioned context of process function. */
>     NonPartitionedContext<?> getNonPartitionedContext();
>
>     ...
> }
> ```

#### Requirement Summary
This section specifies the `WatermarkManager` interface added to `NonPartitionedContext` and the extraction of `NonPartitionedContext` from `PartitionedContext`. The PR implements the API interfaces and their default runtime implementations in the datastream module.

**File proportion:** 6/136 files mapped (4.4%) + 6/136 files associated (4.4%) = 12/136 accounted (8.8%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkManager.java` | Added | +36 / -0 | `WatermarkManager` | `WatermarkManager.emitWatermark` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/NonPartitionedContext.java` | Modified | +8 / -0 | `NonPartitionedContext` | `NonPartitionedContext.getWatermarkManager` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/PartitionedContext.java` | Modified | +4 / -10 | `PartitionedContext` | `PartitionedContext.getStateManager`, `PartitionedContext.getProcessingTimeManager`, `PartitionedContext.getNonPartitionedContext` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputNonPartitionedContext.java` | Modified | +8 / -0 | `TwoOutputNonPartitionedContext` | `TwoOutputNonPartitionedContext.getWatermarkManager` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputPartitionedContext.java` | Added | +27 / -0 | `TwoOutputPartitionedContext` | `TwoOutputPartitionedContext.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/watermark/DefaultWatermarkManager.java` | Added | +57 / -0 | `DefaultWatermarkManager` | `DefaultWatermarkManager.DefaultWatermarkManager`, `DefaultWatermarkManager.emitWatermark` |

#### Modification Summary
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkManager.java`**: Defines the `WatermarkManager` interface for emitting watermarks, as specified.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/NonPartitionedContext.java`**: Adds `getWatermarkManager()` method to `NonPartitionedContext`, as specified.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/PartitionedContext.java`**: Refactored to extend `BasePartitionedContext`, enabling access to `NonPartitionedContext` for watermark emission from partitioned contexts.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputNonPartitionedContext.java`**: Adds `getWatermarkManager()` for two-output contexts, parallel to the `NonPartitionedContext` change.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputPartitionedContext.java`**: New two-output partitioned context interface enabling access to `NonPartitionedContext` in two-output scenarios.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/watermark/DefaultWatermarkManager.java`**: Runtime implementation of `WatermarkManager` that emits watermark events to the output.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/AbstractPartitionedContext.java` | Added | +79 / -0 | Runtime base class for partitioned context implementations must be created to support the new context hierarchy | `AbstractPartitionedContext` | `AbstractPartitionedContext.AbstractPartitionedContext`, `AbstractPartitionedContext.getJobInfo`, `AbstractPartitionedContext.getTaskInfo`, `AbstractPartitionedContext.getStateManager`, `AbstractPartitionedContext.getProcessingTimeManager`, `AbstractPartitionedContext.getMetricGroup` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/BasePartitionedContext.java` | Added | +34 / -0 | New base interface added so `PartitionedContext` and `TwoOutputPartitionedContext` can share state/processing-time accessors; the section is about watermark emission via `getNonPartitionedContext`, which lives on the subinterfaces | `BasePartitionedContext` | `BasePartitionedContext.getStateManager`, `BasePartitionedContext.getProcessingTimeManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContext.java` | Modified | +19 / -3 | Default implementation must be updated to provide `WatermarkManager` access | `DefaultNonPartitionedContext` | `DefaultNonPartitionedContext.DefaultNonPartitionedContext`, `DefaultNonPartitionedContext.getWatermarkManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultPartitionedContext.java` | Modified | +22 / -33 | Default implementation must be refactored to extend the new abstract base and expose `NonPartitionedContext` | `DefaultPartitionedContext` | `DefaultPartitionedContext.DefaultPartitionedContext`, `DefaultPartitionedContext.getJobInfo`, `DefaultPartitionedContext.getTaskInfo`, `DefaultPartitionedContext.getStateManager`, `DefaultPartitionedContext.getProcessingTimeManager`, `DefaultPartitionedContext.setNonPartitionedContext`, `DefaultPartitionedContext.getMetricGroup`, `DefaultPartitionedContext.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContext.java` | Modified | +19 / -3 | Default two-output implementation must be updated to provide `WatermarkManager` access | `DefaultTwoOutputNonPartitionedContext` | `DefaultTwoOutputNonPartitionedContext.DefaultTwoOutputNonPartitionedContext`, `DefaultTwoOutputNonPartitionedContext.getWatermarkManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputPartitionedContext.java` | Added | +69 / -0 | Default two-output partitioned context implementation must be created for the new context interface | `DefaultTwoOutputPartitionedContext` | `DefaultTwoOutputPartitionedContext.DefaultTwoOutputPartitionedContext`, `DefaultTwoOutputPartitionedContext.setNonPartitionedContext`, `DefaultTwoOutputPartitionedContext.getNonPartitionedContext` |

---

## Section 9: Emit watermark from source
*Path: Proposed Changes > Emit Watermark > Emit watermark from source*
*Classification: Implementable*

> For sources we only allow the connector developers (and not users) to send watermarks. So we enable the ability to send a _**watermark**_ in _**`SourceReaderContext`**_.
>
> ```java
> /** The interface that exposes some context from runtime to the {@link SourceReader}. */
> @Public
> public interface SourceReaderContext {
>     ...
>
>     /**
>      * Send the watermark to source output.
>      *
>      * <p>This should only be used for datastream v2.
>      */
>     void emitWatermark(Watermark watermark);
>
>     ...
> }
> ```

#### Requirement Summary
This section specifies adding watermark emission capability to `SourceReaderContext`. The PR adds the `emitWatermark` method to the context interface and implements the emission in `SourceOperator` and its factory.

**File proportion:** 3/136 files mapped (2.2%) + 1/136 files associated (0.7%) = 4/136 accounted (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/api/connector/source/SourceReaderContext.java` | Modified | +10 / -0 | `SourceReaderContext` | `SourceReaderContext.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperator.java` | Modified | +17 / -1 | `SourceOperator` | `SourceOperator.SourceOperator`, `SourceOperator.initReader`, `SourceOperator.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperatorFactory.java` | Modified | +27 / -3 | `SourceOperatorFactory` | `SourceOperatorFactory.createStreamOperator`, `SourceOperatorFactory.getSourceWatermarkDeclarations`, `SourceOperatorFactory.instantiateSourceOperator` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/api/connector/source/SourceReaderContext.java`**: Adds the `emitWatermark(Watermark)` method to the interface, as specified.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperator.java`**: Implements watermark emission logic in the source operator, wiring `SourceReaderContext.emitWatermark()` to the output.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperatorFactory.java`**: Updates the factory to configure watermark declarations from the `Source` and pass them to the operator, enabling watermark emission at runtime.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/SourceOperatorStreamTask.java` | Modified | +6 / -0 | Stream task must propagate watermark declarations to the source operator | `AsyncDataOutputToOutput` | `AsyncDataOutputToOutput.emitWatermark` |

---

## Section 10: Combine Watermarks
*Path: Proposed Changes > Combine Watermarks*
*Classification: Implementable*

> An _**Process Function**_ may have multiple upstream inputs, and each input may have multiple degrees of parallelism. As a result, _**Process Function**_ has the opportunity to receive _**watermark**_ from several different channels. However, considering the semantic of watermark itself, we often want to combine/merge _**watermark**_ from various channels before output to the function. 
>
> The channel from which the data comes is not known to the process function, so the combination logic must be provided by the watermark implementation itself. We provide the following combination strategies:
>
> ```java
> /**
>  * The {@link WatermarkCombinationFunction} defines the comparison/combination semantics among
>  * {@link Watermark}s.
>  */
> @Experimental
> public interface WatermarkCombinationFunction extends Function {
>     /**
>      * The {@link BoolWatermarkCombinationFunction} enum defines the combination semantics for
>      * boolean watermarks. It includes logical operations such as {@code OR} and {@code AND}.
>      */
>     @Experimental
>     enum BoolWatermarkCombinationFunction implements WatermarkCombinationFunction {
>         /** Logical OR combination for boolean watermarks. */
>         OR,
>
>         /** Logical AND combination for boolean watermarks. */
>         AND
>     }
>
>     /**
>      * The {@link NumericWatermarkCombinationFunction} enum defines the combination semantics for
>      * numeric watermarks. It includes operations such as {@code MIN} and {@code MAX}.
>      */
>     @Experimental
>     enum NumericWatermarkCombinationFunction implements WatermarkCombinationFunction {
>         /** Minimum value combination for numeric watermarks. */
>         MIN,
>
>         /** Maximum value combination for numeric watermarks. */
>         MAX
>     }
> }
> ```
>
> For an Input, if only some of its channels receive _**watermark**_ , the watermark corresponding to the channel that does not receive is undefined. When doing the combine in this case, we offer two strategies:
>
>   * According to the combination function, decide the default value for the channel that does not receive any watermark, for example, _`Long.MIN_VALUE`_ is the default value used for _**LongWatermark**_ _combineFunctionMax_.
>
>   * Combine only after all channels have received its first watermark.
>
> Therefore, besides _**WatermarkCombinationFunction**_ , We also introduced a Boolean variable to control the two kinds of behavior.
>
> ```java
> /**
>  * The {@link WatermarkCombinationPolicy} defines when and how to the combine {@link Watermark}s.
>  */
> @Experimental
> public class WatermarkCombinationPolicy implements Serializable {
>
>     private static final long serialVersionUID = 1L;
>
>     private WatermarkCombinationFunction watermarkCombinationFunction;
>
>     private boolean combineWaitForAllChannels;
>
>     public WatermarkCombinationPolicy(
>             WatermarkCombinationFunction watermarkCombinationFunction,
>             boolean combineWaitForAllChannels) {
>         this.watermarkCombinationFunction = watermarkCombinationFunction;
>         this.combineWaitForAllChannels = combineWaitForAllChannels;
>     }
>
>     public WatermarkCombinationFunction getWatermarkCombinationFunction() {
>         return watermarkCombinationFunction;
>     }
>
>     public boolean isCombineWaitForAllChannels() {
>         return combineWaitForAllChannels;
>     }
> }
> ```

#### Requirement Summary
This section specifies `WatermarkCombinationFunction`, `WatermarkCombinationPolicy`, and the two alignment strategies (default-value vs wait-for-all-channels). The PR implements the API types and the full runtime combiner infrastructure including `LongWatermarkCombiner`, `BoolWatermarkCombiner`, `AlignedWatermarkCombiner`, and the network-level input integration.

**File proportion:** 14/136 files mapped (10.3%) + 15/136 files associated (11.0%) = 29/136 accounted (21.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationFunction.java` | Added | +55 / -0 | `WatermarkCombinationFunction`, `BoolWatermarkCombinationFunction`, `NumericWatermarkCombinationFunction` | — |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationPolicy.java` | Added | +79 / -0 | `WatermarkCombinationPolicy` | `WatermarkCombinationPolicy.WatermarkCombinationPolicy`, `WatermarkCombinationPolicy.getWatermarkCombinationFunction`, `WatermarkCombinationPolicy.isCombineWaitForAllChannels`, `WatermarkCombinationPolicy.equals`, `WatermarkCombinationPolicy.hashCode` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AbstractInternalWatermarkDeclaration.java` | Added | +97 / -0 | `AbstractInternalWatermarkDeclaration` | `AbstractInternalWatermarkDeclaration.AbstractInternalWatermarkDeclaration`, `AbstractInternalWatermarkDeclaration.getIdentifier`, `AbstractInternalWatermarkDeclaration.newWatermark`, `AbstractInternalWatermarkDeclaration.getCombinationPolicy`, `AbstractInternalWatermarkDeclaration.getDefaultHandlingStrategy`, `AbstractInternalWatermarkDeclaration.isAligned`, `AbstractInternalWatermarkDeclaration.createWatermarkCombiner`, `AbstractInternalWatermarkDeclaration.from` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/Alignable.java` | Added | +32 / -0 | `Alignable` | `Alignable.isAligned` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableBoolWatermarkDeclaration.java` | Added | +46 / -0 | `AlignableBoolWatermarkDeclaration` | `AlignableBoolWatermarkDeclaration.AlignableBoolWatermarkDeclaration`, `AlignableBoolWatermarkDeclaration.isAligned` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableLongWatermarkDeclaration.java` | Added | +48 / -0 | `AlignableLongWatermarkDeclaration` | `AlignableLongWatermarkDeclaration.AlignableLongWatermarkDeclaration`, `AlignableLongWatermarkDeclaration.isAligned` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignedWatermarkCombiner.java` | Added | +70 / -0 | `AlignedWatermarkCombiner` | `AlignedWatermarkCombiner.AlignedWatermarkCombiner`, `AlignedWatermarkCombiner.combineWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/BoolWatermarkCombiner.java` | Added | +125 / -0 | `BoolWatermarkCombiner` | `BoolWatermarkCombiner.BoolWatermarkCombiner`, `BoolWatermarkCombiner.combineWatermark`, `BoolWatermarkCombiner.shouldEmitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalBoolWatermarkDeclaration.java` | Added | +69 / -0 | `InternalBoolWatermarkDeclaration` | `InternalBoolWatermarkDeclaration.InternalBoolWatermarkDeclaration`, `InternalBoolWatermarkDeclaration.newWatermark`, `InternalBoolWatermarkDeclaration.createWatermarkCombiner` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalLongWatermarkDeclaration.java` | Added | +68 / -0 | `InternalLongWatermarkDeclaration` | `InternalLongWatermarkDeclaration.InternalLongWatermarkDeclaration`, `InternalLongWatermarkDeclaration.newWatermark`, `InternalLongWatermarkDeclaration.createWatermarkCombiner` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/LongWatermarkCombiner.java` | Added | +184 / -0 | `LongWatermarkCombiner`, `LongWatermarkElement` | `LongWatermarkCombiner.LongWatermarkCombiner`, `LongWatermarkCombiner.combineWatermark`, `LongWatermarkCombiner.shouldEmitWatermark`, `LongWatermarkElement.LongWatermarkElement`, `LongWatermarkElement.getInternalIndex`, `LongWatermarkElement.setInternalIndex`, `LongWatermarkElement.setWatermarkValue`, `LongWatermarkElement.getWatermarkValue` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/WatermarkCombiner.java` | Added | +35 / -0 | `WatermarkCombiner` | `WatermarkCombiner.combineWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java` | Modified | +71 / -2 | `AbstractStreamTaskNetworkInput` | `AbstractStreamTaskNetworkInput.AbstractStreamTaskNetworkInput`, `AbstractStreamTaskNetworkInput.emitNext`, `AbstractStreamTaskNetworkInput.processEvent`, `AbstractStreamTaskNetworkInput.processWatermarkEvent` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInput.java` | Modified | +23 / -1 | `StreamTaskNetworkInput` | `StreamTaskNetworkInput.StreamTaskNetworkInput` |

#### Modification Summary
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationFunction.java`**: Defines the `WatermarkCombinationFunction` interface with built-in strategies (MIN, MAX, AND, OR), as specified.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationPolicy.java`**: Defines the `WatermarkCombinationPolicy` class with the boolean `waitForAllChannels` flag, implementing the two alignment strategies described in the section.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AbstractInternalWatermarkDeclaration.java`**: Internal base class for watermark declarations that carry combination semantics.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/Alignable.java`**: Interface for declarations that support alignment (waiting for all channels), implementing the "combine only after all channels" strategy.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableBoolWatermarkDeclaration.java`**: Alignable variant of `BoolWatermarkDeclaration` for the wait-for-all-channels strategy.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableLongWatermarkDeclaration.java`**: Alignable variant of `LongWatermarkDeclaration` for the wait-for-all-channels strategy.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignedWatermarkCombiner.java`**: Combiner implementation that waits for all channels before combining, implementing the second alignment strategy.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/BoolWatermarkCombiner.java`**: Combiner implementation for `BoolWatermark` using AND/OR combination functions with default value or aligned semantics.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalBoolWatermarkDeclaration.java`**: Internal runtime declaration for bool watermarks that creates the appropriate combiner.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalLongWatermarkDeclaration.java`**: Internal runtime declaration for long watermarks that creates the appropriate combiner.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/LongWatermarkCombiner.java`**: Combiner implementation for `LongWatermark` using MIN/MAX combination functions with default value or aligned semantics.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/WatermarkCombiner.java`**: Base interface for all watermark combiner implementations.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java`**: Core integration point where generalized watermark events are intercepted from the network and dispatched to combiners.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInput.java`**: Concrete network input implementation updated to instantiate and wire watermark combiners from declarations.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/pom.xml` | Modified | +6 / -0 | Build dependency must be added for watermark combiner test utilities | — | — |
| `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/InputGate.java` | Modified | +2 / -0 | Input gate interface must expose channel count for combiner initialization | `InputGate` | `InputGate.resumeGateConsumption` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/SingleInputGate.java` | Modified | +7 / -0 | Implementation must provide channel count for combiner initialization | `SingleInputGate` | `SingleInputGate.resumeGateConsumption` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/UnionInputGate.java` | Modified | +6 / -0 | Union gate implementation must provide channel count for combiner initialization | `UnionInputGate` | `UnionInputGate.resumeGateConsumption` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/taskmanager/InputGateWithMetrics.java` | Modified | +4 / -0 | Metrics wrapper must delegate the new channel count method | `InputGateWithMetrics` | `InputGateWithMetrics.resumeGateConsumption` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/MultiInputSortingDataInput.java` | Modified | +4 / -0 | Sorting input must handle watermark events during sort processing | `SortingPhaseDataOutput` | `SortingPhaseDataOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/SortingDataInput.java` | Modified | +4 / -0 | Sorting input must handle watermark events during sort processing | `ForwardingDataOutput` | `ForwardingDataOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamMultipleInputProcessorFactory.java` | Modified | +8 / -1 | Multi-input processor factory must pass watermark declarations to network inputs | `StreamMultipleInputProcessorFactory`, `StreamTaskNetworkOutput` | `StreamMultipleInputProcessorFactory.create`, `StreamTaskNetworkOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputFactory.java` | Modified | +6 / -2 | Factory must accept and propagate watermark declarations | `StreamTaskNetworkInputFactory` | `StreamTaskNetworkInputFactory.create` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTwoInputProcessorFactory.java` | Modified | +14 / -2 | Two-input processor factory must pass watermark declarations to network inputs | `StreamTwoInputProcessorFactory`, `StreamTaskNetworkOutput` | `StreamTwoInputProcessorFactory.create`, `StreamTaskNetworkOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/checkpointing/CheckpointedInputGate.java` | Modified | +4 / -0 | Checkpointed gate must delegate the new channel count method | `CheckpointedInputGate` | `CheckpointedInputGate.resumeGateConsumption` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/recovery/RescalingStreamTaskNetworkInput.java` | Modified | +2 / -2 | Rescaling input must be updated for the new network input constructor | `RescalingStreamTaskNetworkInput` | `RescalingStreamTaskNetworkInput.processEvent` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/OneInputStreamTask.java` | Modified | +13 / -1 | One-input stream task must pass watermark declarations when creating network inputs | `OneInputStreamTask`, `StreamTaskNetworkOutput` | `OneInputStreamTask.createTaskInput`, `StreamTaskNetworkOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermarkstatus/HeapPriorityQueue.java` | Modified | +2 / -2 | Priority queue visibility change needed for watermark combiner reuse | `PriorityComparator`, `HeapPriorityQueueElement` | — |
| `pom.xml` | Modified | +3 / -0 | Root POM must include new dependency versions used by watermark combiners | — | — |

---

## Section 11: Handle Watermarks in Process Function
*Path: Proposed Changes > Handle Watermarks in Process Function*
*Classification: Implementable*

> Different from combining _**watermark**_ between channels, _**Process Function**_ is aware of which Input the watermark comes from. So the watermarks from multiple inputs should be handled by _**Process Function**_ or runtime framework.
>
> We introduced corresponding **_`onWatermark`_** method to all type of _**Process Function**_ , which will be used as a callback when _**watermark**_ is received from a single input, and its return value is an enum class indicating whether the watermark's ownership is transferred to _**Process Function**_.
>
> The handling strategy between inputs depends on the logic of the _**Process Function**_ itself. For most functions, we may only need the same strategy: Forwarding it to downstream or not. Therefore, we will allow the user to define the default handling strategy, and the framework uses it to handle watermarks when `_**onWatermark**_ `returns _**`WatermarkHandlingResult.PEEK`**_.
>
> ```java
> /** This class defines watermark handling result for process function. */
> public enum WatermarkHandlingResult {
>     /** Process function only peek the watermark, and it's framework's responsibility to handle this watermark. */
>     PEEK,
>     /** This watermark should be sent to downstream by process function itself. The framework does no additional processing. */
>     POLL,
> }
> ```
>
> ```java
> /**
>  * This class defines the framework's behavior when the user-defined {@link Watermark} process method returns {@link
>  * WatermarkHandlingResult#PEEK}.
>  */
> @Experimental
> public enum WatermarkHandlingStrategy {
>     /** The framework shouldn't take any action. */
>     IGNORE,
>
>     /** The framework should send the watermark to downstream. */
>     FORWARD,
> }
> ```

#### Requirement Summary
This section specifies `WatermarkHandlingResult`, `WatermarkHandlingStrategy`, and the general `onWatermark` callback pattern on process functions. The PR implements the enums and integrates watermark handling into the operator and output infrastructure.

**File proportion:** 3/136 files mapped (2.2%) + 20/136 files associated (14.7%) = 23/136 accounted (16.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingResult.java` | Added | +37 / -0 | `WatermarkHandlingResult` | — |
| `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingStrategy.java` | Added | +34 / -0 | `WatermarkHandlingStrategy` | — |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/Input.java` | Modified | +8 / -0 | `Input` | `Input.processWatermark` |

#### Modification Summary
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingResult.java`**: Defines the `WatermarkHandlingResult` enum (`PEEK`, `POLL`) as specified, indicating whether the watermark's ownership is transferred to the process function.
- **`flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkHandlingStrategy.java`**: Defines the `WatermarkHandlingStrategy` enum for default watermark handling (FORWARD, IGNORE), as specified.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/Input.java`**: Adds the `processWatermark(WatermarkEvent)` method to the operator-level `Input` interface, enabling the runtime to dispatch generalized watermarks to operators.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/AbstractStreamOperator.java` | Modified | +16 / -0 | Base operator must provide default watermark handling implementation | `AbstractStreamOperator` | `AbstractStreamOperator.processWatermark`, `AbstractStreamOperator.processWatermark1`, `AbstractStreamOperator.processWatermark2` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/CountingOutput.java` | Modified | +6 / -0 | Counting output must delegate the new `emitWatermark` method | `CountingOutput` | `CountingOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/Output.java` | Modified | +8 / -0 | Output interface must support emitting generalized watermarks | `Output` | `Output.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/TimestampedCollector.java` | Modified | +6 / -0 | Collector must delegate the new `emitWatermark` method | `TimestampedCollector` | `TimestampedCollector.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/AbstractAsyncStateStreamOperator.java` | Modified | +43 / -0 | Async state operator must handle generalized watermarks | `AbstractAsyncStateStreamOperator` | `AbstractAsyncStateStreamOperator.processWatermarkInternal`, `AbstractAsyncStateStreamOperator.processWatermark1Internal`, `AbstractAsyncStateStreamOperator.processWatermark2Internal`, `AbstractAsyncStateStreamOperator.processWatermark`, `AbstractAsyncStateStreamOperator.processWatermark1`, `AbstractAsyncStateStreamOperator.processWatermark2` |
| `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/TimestampedCollectorWithDeclaredVariable.java` | Modified | +6 / -0 | Async collector must delegate the new `emitWatermark` method | `TimestampedCollectorWithDeclaredVariable` | `TimestampedCollectorWithDeclaredVariable.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/FinishedDataOutput.java` | Modified | +6 / -0 | Finished output must implement the new watermark method as no-op | `FinishedDataOutput` | `FinishedDataOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/PushingAsyncDataInput.java` | Modified | +3 / -0 | Async data input interface must include watermark method | `DataOutput` | `DataOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/RecordWriterOutput.java` | Modified | +18 / -0 | Record writer output must serialize and emit watermark events to downstream | `RecordWriterOutput` | `RecordWriterOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/BroadcastingOutputCollector.java` | Modified | +8 / -0 | Broadcasting collector must forward watermarks to all outputs | `BroadcastingOutputCollector` | `BroadcastingOutputCollector.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/ChainingOutput.java` | Modified | +10 / -0 | Chaining output must forward watermarks to downstream operator | `ChainingOutput` | `ChainingOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/FinishedOnRestoreMainOperatorOutput.java` | Modified | +8 / -0 | Finished-on-restore output must implement watermark method as no-op | `FinishedOnRestoreMainOperatorOutput` | `FinishedOnRestoreMainOperatorOutput.emitWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/StreamIterationTail.java` | Modified | +4 / -0 | Iteration tail must handle watermark events | `IterationTailOutput` | `IterationTailOutput.emitWatermark` |
| `flink-libraries/flink-state-processing-api/src/main/java/org/apache/flink/state/api/output/operators/StateBootstrapWrapperOperator.java` | Modified | +4 / -0 | State bootstrap operator must implement the new watermark method | `VoidOutput` | `VoidOutput.emitWatermark` |
| `flink-libraries/flink-state-processing-api/src/main/java/org/apache/flink/state/api/output/operators/StateBootstrapWrapperOperatorFactory.java` | Modified | +4 / -0 | State bootstrap operator factory must implement the new watermark method | `VoidOutput` | `VoidOutput.emitWatermark` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/BroadcastingOutput.java` | Modified | +8 / -0 | Table runtime broadcasting output must forward watermarks | `BroadcastingOutput` | `BroadcastingOutput.emitWatermark` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/CopyingSecondInputOfTwoInputStreamOperatorOutput.java` | Modified | +10 / -0 | Table runtime output must handle watermark propagation | `CopyingSecondInputOfTwoInputStreamOperatorOutput` | `CopyingSecondInputOfTwoInputStreamOperatorOutput.emitWatermark` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/FirstInputOfTwoInputStreamOperatorOutput.java` | Modified | +10 / -0 | Table runtime output must handle watermark propagation | `FirstInputOfTwoInputStreamOperatorOutput` | `FirstInputOfTwoInputStreamOperatorOutput.emitWatermark` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/OneInputStreamOperatorOutput.java` | Modified | +10 / -0 | Table runtime output must handle watermark propagation | `OneInputStreamOperatorOutput` | `OneInputStreamOperatorOutput.emitWatermark` |
| `flink-table/flink-table-runtime/src/main/java/org/apache/flink/table/runtime/operators/multipleinput/output/SecondInputOfTwoInputStreamOperatorOutput.java` | Modified | +10 / -0 | Table runtime output must handle watermark propagation | `SecondInputOfTwoInputStreamOperatorOutput` | `SecondInputOfTwoInputStreamOperatorOutput.emitWatermark` |

---

## Section 12: OneInputStreamProcessFunction
*Path: Proposed Changes > Handle Watermarks in Process Function > OneInputStreamProcessFunction*
*Classification: Implementable*

> ```java
> /** 
> * This contains all logical related to process records from single input. 
> */
> @Experimental
> public interface OneInputStreamProcessFunction<IN, OUT> extends ProcessFunction {
>
>   ...
>
>     /** Callback function when receive watermark. */
>     default WatermarkHandlingResult onWatermark(
>             Watermark watermark, Collector<OUT> output, NonPartitionedContext<OUT> ctx) {
>       return WatermarkHandlingResult.PEEK;
>      }
>
>   ...
>
> }
> ```

#### Requirement Summary
This section specifies the `onWatermark` callback method on `OneInputStreamProcessFunction`. The PR adds the method to the API interface and integrates it into the process operator and keyed process operator runtime implementations.

**File proportion:** 1/136 files mapped (0.7%) + 3/136 files associated (2.2%) = 4/136 accounted (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/OneInputStreamProcessFunction.java` | Modified | +8 / -0 | `OneInputStreamProcessFunction` | `OneInputStreamProcessFunction.onWatermark` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/OneInputStreamProcessFunction.java`**: Adds the `onWatermark` method with `WatermarkHandlingResult` return type, as specified in the Java code block.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | Modified | +7 / -1 | Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed one-input operator can route generalized-watermark callbacks; does not itself invoke `onWatermark` | `KeyedProcessOperator` | `KeyedProcessOperator.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | Modified | +43 / -3 | Non-keyed process operator must invoke the new `onWatermark` callback and implement watermark handling strategy | `ProcessOperator` | `ProcessOperator.open`, `ProcessOperator.processWatermarkInternal`, `ProcessOperator.getNonPartitionedContext` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/KeyedProcessOperator.java` | Modified | +6 / -0 | Runtime keyed process operator must handle generalized watermark events | `KeyedProcessOperator` | `KeyedProcessOperator.processWatermark` |

---

## Section 13: TwoInputBroadcastStreamProcessFunction
*Path: Proposed Changes > Handle Watermarks in Process Function > TwoInputBroadcastStreamProcessFunction*
*Classification: Implementable*

> Note: In the case of two inputs, it is up to the user to ensure that the same _**watermark**_ on two inputs is not incorrectly processed. For example, if the _**watermark**_ of Input1 is processed by the UDF and Input2 is handled by the framework, the correctness of the result is not guaranteed.
>
> ```java
> /**
>  * This contains all logical related to process records from a broadcast stream and a non-broadcast
>  * stream.
>  */
> @Experimental
> public interface TwoInputBroadcastStreamProcessFunction<IN1, IN2, OUT> extends ProcessFunction {
>
>     ...
>
>     /**
>      * Callback function when receive the watermark from broadcast input
>      *
>      * @param watermark to process.
>      * @param output to emit record.
>      * @param ctx, runtime context in which this function is executed.
>      */
>     default WatermarkHandlingResult onWatermarkFromBroadcastInput(
>             Watermark watermark,
>             Collector<OUT> output,
>             NonPartitionedContext<OUT> ctx) {
>       return WatermarkHandlingResult.PEEK;
>     }
>
>     /**
>      * Callback function when receive the watermark from non-broadcast input
>      *
>      * @param watermark to process.
>      * @param output to emit record.
>      * @param ctx, runtime context in which this function is executed.
>      */
>     default WatermarkHandlingResult onWatermarkFromNonBroadcastInput(
>             Watermark watermark, Collector<OUT> output, NonPartitionedContext<OUT> ctx) {
>       return WatermarkHandlingResult.PEEK;
>     }
>
>    ...
>
> }
> ```

#### Requirement Summary
This section specifies the `onWatermark` callbacks on `TwoInputBroadcastStreamProcessFunction` for both inputs. The PR adds the `onFirstInputWatermark` and `onSecondInputWatermark` methods and integrates them into the two-input broadcast operator implementations.

**File proportion:** 1/136 files mapped (0.7%) + 3/136 files associated (2.2%) = 4/136 accounted (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputBroadcastStreamProcessFunction.java` | Modified | +26 / -0 | `TwoInputBroadcastStreamProcessFunction` | `TwoInputBroadcastStreamProcessFunction.onWatermarkFromBroadcastInput`, `TwoInputBroadcastStreamProcessFunction.onWatermarkFromNonBroadcastInput` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputBroadcastStreamProcessFunction.java`**: Adds `onWatermarkFromBroadcastInput` and `onWatermarkFromNonBroadcastInput` methods with `WatermarkHandlingResult` return type, as specified.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java` | Modified | +7 / -1 | Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-input broadcast operator can route generalized-watermark callbacks; does not itself invoke the callbacks | `KeyedTwoInputBroadcastProcessOperator` | `KeyedTwoInputBroadcastProcessOperator.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java` | Modified | +55 / -3 | Two-input broadcast operator must invoke the new watermark callbacks and implement handling strategy | `TwoInputBroadcastProcessOperator` | `TwoInputBroadcastProcessOperator.open`, `TwoInputBroadcastProcessOperator.processWatermark1Internal`, `TwoInputBroadcastProcessOperator.processWatermark2Internal`, `TwoInputBroadcastProcessOperator.getNonPartitionedContext` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/TwoInputStreamOperator.java` | Modified | +15 / -0 | Two-input operator interface must support generalized watermark processing on both inputs | `TwoInputStreamOperator` | `TwoInputStreamOperator.processWatermark1`, `TwoInputStreamOperator.processWatermark2` |

---

## Section 14: TwoInputNonBroadcastStreamProcessFunction
*Path: Proposed Changes > Handle Watermarks in Process Function > TwoInputNonBroadcastStreamProcessFunction*
*Classification: Implementable*

> ```java
> /** This contains all logical related to process records from two non-broadcast input. */
> @Experimental
> public interface TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> extends ProcessFunction {
>
>     ...
>
>     /**
>      * Callback function when receive the watermark from the first input
>      *
>      * @param watermark to process.
>      * @param output to emit record.
>      * @param ctx, runtime context in which this function is executed.
>      */
>     default WatermarkHandlingResult onWatermarkFromFirstInput(
>             Watermark watermark,
>             Collector<OUT> output,
>             NonPartitionedContext<OUT> ctx) {
>       return WatermarkHandlingResult.PEEK;
>     }
>
>     /**
>      * Callback function when receive the watermark from the second input
>      *
>      * @param watermark to process.
>      * @param output to emit record.
>      * @param ctx, runtime context in which this function is executed.
>      */
>     default WatermarkHandlingResult onWatermarkFromSecondInput(
>             Watermark watermark,
>             Collector<OUT> output,
>             NonPartitionedContext<OUT> ctx) {
>       return WatermarkHandlingResult.PEEK;
>     }
>
>   ...
>
> }
> ```

#### Requirement Summary
This section specifies the `onWatermark` callbacks on `TwoInputNonBroadcastStreamProcessFunction` for both inputs. The PR adds the methods to the API interface and integrates them into the two-input non-broadcast operator implementations.

**File proportion:** 1/136 files mapped (0.7%) + 2/136 files associated (1.5%) = 3/136 accounted (2.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputNonBroadcastStreamProcessFunction.java` | Modified | +26 / -0 | `TwoInputNonBroadcastStreamProcessFunction` | `TwoInputNonBroadcastStreamProcessFunction.onWatermarkFromFirstInput`, `TwoInputNonBroadcastStreamProcessFunction.onWatermarkFromSecondInput` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputNonBroadcastStreamProcessFunction.java`**: Adds `onWatermarkFromFirstInput` and `onWatermarkFromSecondInput` methods with `WatermarkHandlingResult` return type, as specified.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | Modified | +7 / -1 | Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-input non-broadcast operator can route generalized-watermark callbacks; does not itself invoke the callbacks | `KeyedTwoInputNonBroadcastProcessOperator` | `KeyedTwoInputNonBroadcastProcessOperator.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java` | Modified | +55 / -3 | Two-input non-broadcast operator must invoke the new watermark callbacks and implement handling strategy | `TwoInputNonBroadcastProcessOperator` | `TwoInputNonBroadcastProcessOperator.open`, `TwoInputNonBroadcastProcessOperator.processWatermark1Internal`, `TwoInputNonBroadcastProcessOperator.processWatermark2Internal`, `TwoInputNonBroadcastProcessOperator.getNonPartitionedContext` |

---

## Section 15: TwoOutputStreamProcessFunction
*Path: Proposed Changes > Handle Watermarks in Process Function > TwoOutputStreamProcessFunction*
*Classification: Implementable*

> ```java
> /** This contains all logical related to process and emit records to two output streams. */
> @Experimental
> public interface TwoOutputStreamProcessFunction<IN, OUT1, OUT2> extends ProcessFunction {
>
>      ...
>
>     /**
>      * Callback function when receive the watermark from the input.
>      *
>      * @param watermark to process.
>      * @param output1 to emit data to the first output.
>      * @param output2 to emit data to the second output.
>      * @param ctx, runtime context in which this function is executed.
>      */
>     default WatermarkHandlingResult onWatermark(
>             Watermark watermark,
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputNonPartitionedContext<OUT1, OUT2> ctx) {
>         return WatermarkHandlingResult.PEEK;
>     }
>
>     ...
>
> }
> ```

#### Requirement Summary
This section specifies the `onWatermark` callback on `TwoOutputStreamProcessFunction`. The PR adds the method to the API interface and integrates it into the two-output operator implementations.

**File proportion:** 1/136 files mapped (0.7%) + 3/136 files associated (2.2%) = 4/136 accounted (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputStreamProcessFunction.java` | Modified | +24 / -3 | `TwoOutputStreamProcessFunction` | `TwoOutputStreamProcessFunction.onWatermark`, `TwoOutputStreamProcessFunction.processRecord`, `TwoOutputStreamProcessFunction.onProcessingTimer` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputStreamProcessFunction.java`**: Adds the `onWatermark` method with `WatermarkHandlingResult` return type for two-output process functions, as specified.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputApplyPartitionFunction.java` | Modified | +5 / -2 | Two-output apply partition function must be updated for consistency with the new watermark callback pattern | `TwoOutputApplyPartitionFunction` | `TwoOutputApplyPartitionFunction.apply` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | Modified | +8 / -1 | Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-output operator can route generalized-watermark callbacks; does not itself invoke the callback | `KeyedTwoOutputProcessOperator` | `KeyedTwoOutputProcessOperator.getNonPartitionedContext` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java` | Modified | +46 / -4 | Two-output operator must invoke the new watermark callback and implement handling strategy | `TwoOutputProcessOperator` | `TwoOutputProcessOperator.open`, `TwoOutputProcessOperator.processWatermarkInternal`, `TwoOutputProcessOperator.getNonPartitionedContext` |

---

## Section 17: Test Plan
*Classification: Implementable*

> We will provide unit and integration tests to validate the proposed changes.

#### Requirement Summary
This section specifies that unit and integration tests will be provided. The PR includes a comprehensive end-to-end `WatermarkITCase` integration test, watermark combiner unit tests, watermark declaration tests, context tests, operator tests, and updates to existing test infrastructure to support generalized watermarks.

**File proportion:** 32/136 files mapped (23.5%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-connectors/flink-connector-base/src/test/java/org/apache/flink/connector/base/source/reader/SourceReaderBaseTest.java` | Modified | +4 / -0 | — | — |
| `flink-core-api/src/test/java/org/apache/flink/api/common/watermark/WatermarkDeclarationsTest.java` | Added | +91 / -0 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/attribute/StreamingJobGraphGeneratorWithAttributeTest.java` | Modified | +2 / -1 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContextTest.java` | Modified | +36 / -25 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContextTest.java` | Modified | +36 / -25 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/functions/ProcessFunctionTest.java` | Modified | +2 / -1 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperatorTest.java` | Modified | +4 / -4 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperatorTest.java` | Modified | +3 / -3 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/stream/StreamTestUtils.java` | Modified | +2 / -1 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/StreamUtilsTest.java` | Modified | +2 / -1 | — | — |
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/WatermarkUtilsTest.java` | Added | +182 / -0 | — | — |
| `flink-datastream/src/test/resources/log4j2-test.properties` | Added | +31 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializerTest.java` | Modified | +22 / -1 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/SourceOperatorTest.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/CollectingDataOutput.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/LargeSortingDataInputITCase.java` | Modified | +4 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/CollectingDataOutput.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/TestingSourceOperator.java` | Modified | +2 / -1 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/watermark/generalized/WatermarkCombinerTest.java` | Added | +405 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockIndexedInputGate.java` | Modified | +3 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockInputGate.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/checkpointing/AlignedCheckpointsMassiveRandomTest.java` | Modified | +3 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/runtime/watermarkstatus/StatusWatermarkValveTest.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/util/AbstractStreamOperatorTestHarness.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/util/CollectorOutput.java` | Modified | +24 / -8 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/util/MockOutput.java` | Modified | +6 / -0 | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/util/SourceOperatorTestHarness.java` | Modified | +6 / -0 | — | — |
| `flink-streaming-java/src/test/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputTest.java` | Modified | +4 / -0 | — | — |
| `flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/runtime/utils/TimeTestUtil.scala` | Modified | +4 / -0 | — | — |
| `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/multipleinput/output/BlackHoleOutput.java` | Modified | +6 / -0 | — | — |
| `flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/over/NonBufferOverWindowOperatorTest.java` | Modified | +6 / -0 | — | — |
| `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/WatermarkITCase.java` | Added | +1097 / -0 | — | — |

#### Modification Summary
- **`flink-connectors/flink-connector-base/src/test/java/org/apache/flink/connector/base/source/reader/SourceReaderBaseTest.java`**: Validates the new `SourceReaderContext.emitWatermark()` interface method introduced for source watermark emission.
- **`flink-core-api/src/test/java/org/apache/flink/api/common/watermark/WatermarkDeclarationsTest.java`**: Unit tests for the watermark declaration builder.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/attribute/StreamingJobGraphGeneratorWithAttributeTest.java`**: Validates job-graph propagation of generalized watermark attributes.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContextTest.java`**: Validates the non-partitioned context with the new `WatermarkManager` accessor.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContextTest.java`**: Validates the two-output non-partitioned context with the new `WatermarkManager` accessor.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/functions/ProcessFunctionTest.java`**: Validates the `ProcessFunction` watermark declaration method.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperatorTest.java`**: Validates watermark handling in keyed two-output process operators.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperatorTest.java`**: Validates watermark handling in non-keyed two-output process operators.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/stream/StreamTestUtils.java`**: Test utility supporting the generalized watermark tests.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/StreamUtilsTest.java`**: Validates watermark declaration/propagation behavior in stream utilities.
- **`flink-datastream/src/test/java/org/apache/flink/datastream/impl/utils/WatermarkUtilsTest.java`**: Unit tests for the generalized watermark utility helpers.
- **`flink-datastream/src/test/resources/log4j2-test.properties`**: Logging configuration used by the datastream watermark test suite.
- **`flink-runtime/src/test/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializerTest.java`**: Validates serialization/deserialization of `WatermarkEvent`.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/SourceOperatorTest.java`**: Validates source operator generalized-watermark emission.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/CollectingDataOutput.java`**: Test helper that captures watermark events for sorting input tests.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/sort/LargeSortingDataInputITCase.java`**: Integration test that exercises sorting input under generalized watermarks.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/CollectingDataOutput.java`**: Test helper for source-side watermark tests.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/operators/source/TestingSourceOperator.java`**: Testing source operator that supports watermark declaration.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/api/watermark/generalized/WatermarkCombinerTest.java`**: Comprehensive unit tests for all watermark combiner implementations.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockIndexedInputGate.java`**: Mock indexed input gate updated for watermark channel-count assertions.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/MockInputGate.java`**: Mock input gate updated for watermark channel-count assertions.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/runtime/io/checkpointing/AlignedCheckpointsMassiveRandomTest.java`**: Validates aligned-checkpoint behavior with generalized watermarks.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/runtime/watermarkstatus/StatusWatermarkValveTest.java`**: Validates watermark status valve behavior under the new watermark event types.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/util/AbstractStreamOperatorTestHarness.java`**: Operator test harness that handles generalized watermarks.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/util/CollectorOutput.java`**: Collector output that captures watermark events for operator tests.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/util/MockOutput.java`**: Mock output handles generalized watermarks for operator tests.
- **`flink-runtime/src/test/java/org/apache/flink/streaming/util/SourceOperatorTestHarness.java`**: Source operator test harness used by generalized watermark source tests.
- **`flink-streaming-java/src/test/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputTest.java`**: Validates generalized watermark handling through stream task network inputs.
- **`flink-table/flink-table-planner/src/test/scala/org/apache/flink/table/planner/runtime/utils/TimeTestUtil.scala`**: Planner runtime time test utility updated for generalized watermark support.
- **`flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/multipleinput/output/BlackHoleOutput.java`**: Table-runtime test output that handles generalized watermarks.
- **`flink-table/flink-table-runtime/src/test/java/org/apache/flink/table/runtime/operators/over/NonBufferOverWindowOperatorTest.java`**: Validates over-window operator under generalized watermarks.
- **`flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/WatermarkITCase.java`**: Comprehensive end-to-end integration test for generalized watermarks in DataStream programs.

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

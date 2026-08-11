# Apache Flink - FLIP-499: Support Event Time by Generalized Watermark in DataStream V2

**PR:** https://github.com/apache/flink/pull/25978
**Requirement Doc:** https://cwiki.apache.org/confluence/display/FLINK/FLIP-499

## Matching Statistics
- **Requirement Doc Coverage:** 6/6 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 27/36 files mapped (75.0%) + 9/36 files associated (25.0%) = 36/36 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | FLIP-499: Support Event Time by Generalized Watermark in DataStream V2 | No | N/A | knowledge |
| 2 | Background | No | N/A | knowledge |
| 3 | Example | No | N/A | knowledge |
| 4 | Proposed Changes | No | N/A | knowledge |
| 5 | Step 1 Watermarks Definition | No | N/A | knowledge |
| 6 | Event Time Watermark Definition | Yes | Yes | implementation |
| 7 | Idle Status Watermark Definition | Yes | Yes | implementation |
| 8 | Step 2 Generate Watermarks | No | N/A | knowledge |
| 9 | Generate watermarks by provided WatermarkGeneratorBuilder | Yes | Yes | implementation |
| 10 | Generate watermarks by user-defined ProcessFunction | No | N/A | contextual |
| 11 | Step 3 Handle Watermarks | No | N/A | knowledge |
| 12 | Handle watermarks by provided EventTimeProcessFunction | Yes | Yes | implementation |
| 13 | Handle watermarks by user-defined ProcessFunction | Yes | Yes | implementation |
| 14 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 15 | Test Plan | Yes | Yes | evaluation |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `flink-core/src/main/java/org/apache/flink/api/common/eventtime/WatermarksWithIdleness.java` | source | — | Section 9 |
| 2 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | source | Section 6, Section 7, Section 9, Section 12, Section 13 | — |
| 3 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/EventTimeProcessFunction.java` | source | Section 12 | — |
| 4 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/OneInputEventTimeStreamProcessFunction.java` | source | Section 12 | — |
| 5 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputBroadcastEventTimeStreamProcessFunction.java` | source | Section 12 | — |
| 6 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputNonBroadcastEventTimeStreamProcessFunction.java` | source | Section 12 | — |
| 7 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoOutputEventTimeStreamProcessFunction.java` | source | Section 12 | — |
| 8 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeExtractor.java` | source | Section 9 | — |
| 9 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkGeneratorBuilder.java` | source | Section 9 | — |
| 10 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkStrategy.java` | source | Section 9 | — |
| 11 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/timer/EventTimeManager.java` | source | Section 12 | — |
| 12 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` | source | Section 9, Section 12, Section 13 | — |
| 13 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedOneInputStreamProcessFunction.java` | source | Section 12 | — |
| 14 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputBroadcastStreamProcessFunction.java` | source | Section 12 | — |
| 15 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.java` | source | Section 12 | — |
| 16 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoOutputStreamProcessFunction.java` | source | Section 12 | — |
| 17 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunction.java` | source | Section 9 | — |
| 18 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/timer/DefaultEventTimeManager.java` | source | Section 12 | — |
| 19 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | source | Section 12 | — |
| 20 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java` | source | Section 12 | — |
| 21 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | source | Section 12 | — |
| 22 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | source | Section 12 | — |
| 23 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | source | Section 9, Section 12, Section 13 | — |
| 24 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java` | source | Section 12, Section 13 | — |
| 25 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java` | source | Section 12, Section 13 | — |
| 26 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java` | source | Section 12, Section 13 | — |
| 27 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/BroadcastStreamImpl.java` | source | — | Section 12 |
| 28 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java` | source | — | Section 12 |
| 29 | `flink-datastream/src/test/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunctionTest.java` | test | — | Section 15 |
| 30 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java` | source | — | Section 6 |
| 31 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java` | source | Section 6, Section 7 | — |
| 32 | `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java` | source | Section 6, Section 7 | — |
| 33 | `flink-runtime/src/main/java/org/apache/flink/streaming/util/watermark/WatermarkUtils.java` | source | — | Section 6 |
| 34 | `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeExtensionITCase.java` | test | — | Section 15 |
| 35 | `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeWatermarkCombinerTest.java` | test | — | Section 15 |
| 36 | `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeWatermarkHandlerTest.java` | test | — | Section 15 |

---

## Section 6: Event Time Watermark Definition
*Path: Proposed Changes > Step 1 Watermarks Definition > Event Time Watermark Definition*
*Classification: Implementable*

> Before declaring the watermark, let's first define the `EventTimeWatermark`.
>
> In this FLIP, the`EventTimeWatermark` represents a specific timestamp. Once a process function receives the `EventTimeWatermark`, it will no longer receive events with a timestamp earlier than that watermark.
>
> The `EventTimeWatermark` signifies the passing of the time, and since time is represented as a numeric value, the`EventTimeWatermark` is of type long.
>
> For a `ProcessFunction` with multiple input channels, it receives `EventTimeWatermark`s from all of these channels. The `ProcessFunction` should use the minimum of these `EventTimeWatermark`s as its own event time. Otherwise, it is possible for the event time of some inputs to be earlier than the `ProcessFunction`'s own event time. This could lead to the `ProcessFunction` receiving data with an event time earlier than its own, which contradicts the definition of the `EventTimeWatermark`. Therefore, the `EventTimeWatermark` should be combined using the `MIN` function.
>
> Thus, we can define the declaration of the`EventTimeWatermark` as follows:
>
> ```java
> public static final LongWatermarkDeclaration EVENT_TIME_WATERMARK_DECLARATION =
>             WatermarkDeclarations.newBuilder("BUILTIN_API_EVENT_TIME")
>                     .typeLong()
>                     .combineFunctionMin()
>                     .build();
> ```

#### Requirement Summary
This section defines the `EventTimeWatermark` as a long-typed watermark representing a timestamp, combined across multiple input channels using the `MIN` function. The PR implements `EventTimeWatermarkCombiner` which performs MIN-based combination of event time watermarks across inputs, and `EventTimeWatermarkHandler` which manages the event time watermark declaration, creation, and processing within the generalized watermark framework.

**File proportion:** 3/36 files mapped (8.3%) + 2/36 files associated (5.6%) = 5/36 accounted (13.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | Added | +273 / -0 | `EventTimeExtension` | `EventTimeExtension.isEventTimeWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java` | Added | +117 / -0 | `EventTimeWatermarkCombiner`, `WrappedDataOutput` | `EventTimeWatermarkCombiner.EventTimeWatermarkCombiner`, `EventTimeWatermarkCombiner.combineWatermark`, `WrappedDataOutput.WrappedDataOutput`, `WrappedDataOutput.setWatermarkEmitter`, `WrappedDataOutput.emitRecord`, `WrappedDataOutput.emitWatermark`, `WrappedDataOutput.emitLatencyMarker`, `WrappedDataOutput.emitRecordAttributes` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java` | Added | +220 / -0 | `EventTimeWatermarkHandler`, `EventTimeUpdateStatus`, `EventTimeWithIdleStatus` | `EventTimeWatermarkHandler.EventTimeWatermarkHandler`, `EventTimeWatermarkHandler.processEventTime`, `EventTimeWatermarkHandler.tryAdvanceEventTimeAndEmitWatermark`, `EventTimeWatermarkHandler.getCurrentEventTime`, `EventTimeWatermarkHandler.getLastEmitWatermark`, `EventTimeWatermarkHandler.processWatermark`, `EventTimeUpdateStatus.EventTimeUpdateStatus`, `EventTimeUpdateStatus.isEventTimeUpdated`, `EventTimeUpdateStatus.getNewEventTime`, `EventTimeUpdateStatus.ofUpdatedWatermark`, `EventTimeWithIdleStatus.getEventTime`, `EventTimeWithIdleStatus.setEventTime` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`**: Declares the `EVENT_TIME_WATERMARK_DECLARATION` (long-typed, MIN-combined) public constant that matches the requirement's `EventTimeWatermark` definition, and exposes the `isEventTimeWatermark` predicate so the framework and user code can recognize event-time watermarks.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java`**: Implements the `EventTimeWatermark` combiner — `combineWatermark` uses the `MIN` function to combine event-time watermarks from multiple input channels as specified in this section. `WrappedDataOutput.WrappedDataOutput`, `setWatermarkEmitter`, `emitRecord`, `emitWatermark`, `emitLatencyMarker`, and `emitRecordAttributes` are the wrapping data-output methods used by the combiner to forward records/watermarks downstream. The same `combineWatermark` function also dispatches `IDLE_STATUS_WATERMARK_DECLARATION` watermarks; that idle-status behavior belongs to Section 7's IdleStatusWatermark requirement (the unavoidable coarse function ownership documented under Section 7).
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java`**: Implements the event-time watermark side of the handler — tracks per-channel `EventTimeWithIdleStatus.eventTime`, advances the MIN across channels, and emits new event-time watermarks downstream via `processWatermark`.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java` | Modified | +7 / -0 | Updated network input to propagate event time watermarks through the generalized watermark framework | `AbstractStreamTaskNetworkInput` | `AbstractStreamTaskNetworkInput.AbstractStreamTaskNetworkInput` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/util/watermark/WatermarkUtils.java` | Modified | +26 / -0 | Added utility methods for creating and inspecting event time watermarks | `WatermarkUtils` | `WatermarkUtils.addEventTimeWatermarkCombinerIfNeeded` |

---

## Section 7: Idle Status Watermark Definition
*Path: Proposed Changes > Step 1 Watermarks Definition > Idle Status Watermark Definition*
*Classification: Implementable*

> There are situations where some inputs may have no data; for instance, a Kafka partition may be empty due to data skew. If this situation is not handled, the event time of the `ProcessFunction` processing the inputs with no data will cease to update, preventing the job's event time from advancing.
>
> To address this situation, we plan to implement an `IdleStatusWatermark` in DataStream V2 through `Generalized Watermark`. The `IdleStatusWatermark` indicates that a particular input is in an idle state. When a `ProcessFunction` receives an `IdleStatusWatermark` from an input, it should ignore that input when combining `EventTimeWatermark`s.
>
> Since `IdleStatusWatermark` is designed to indicate whether a specific input is idle, it is represented as a boolean type. 
>
> For `ProcessFunction` with input multiple input channels, a `ProcessFunction` is considered idle only if all input channels are idle; therefore, its combination function uses a logical `AND` operation.
>
> Thus, we can define the declaration of the`IdleStatusWatermark` as follows:
>
> ```java
> public static final BoolWatermarkDeclaration IDLE_STATUS_WATERMARK_DECLARATION =
>         WatermarkDeclarations.newBuilder("BUILTIN_API_EVENT_TIME_IDLE")
>                 .typeBool()
>                 .combineFunctionAND()
>                 .build();
> ```

#### Requirement Summary
This section defines the `IdleStatusWatermark` as a boolean-typed watermark indicating input idle status, combined across multiple input channels using a logical `AND` operation (all channels must be idle for the function to be idle). The PR implements idle status tracking within `EventTimeWatermarkHandler` and `EventTimeWatermarkCombiner`, and modifies `WatermarksWithIdleness` to support the idle status detection mechanism.

**File proportion:** 3/36 files mapped (8.3%) + 0/36 files associated (0.0%) = 3/36 accounted (8.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | Added | +273 / -0 | — | `EventTimeExtension.isIdleStatusWatermark` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java` | Added | +117 / -0 | — | `WrappedDataOutput.emitWatermarkStatus` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java` | Added | +220 / -0 | — | `EventTimeWatermarkHandler.processEventTimeIdleStatus`, `EventTimeWatermarkHandler.tryEmitEventTimeIdleStatus`, `EventTimeWatermarkHandler.isAllInputIdle`, `EventTimeWithIdleStatus.isIdle`, `EventTimeWithIdleStatus.setIdleStatus` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`**: Declares the `IDLE_STATUS_WATERMARK_DECLARATION` (boolean-typed, AND-combined) public constant matching the requirement's `IdleStatusWatermark` definition, and exposes the `isIdleStatusWatermark` predicate for downstream recognition.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java`**: `WrappedDataOutput.emitWatermarkStatus` propagates the active/idle status downstream, supporting the IdleStatusWatermark mechanism where idle inputs are excluded from MIN combination. The IDLE_STATUS_WATERMARK_DECLARATION branch that actually triggers this propagation lives inside `combineWatermark` — that function is attributed to Section 6 (Check 28 tuple uniqueness, since `combineWatermark` is one symbol) but its idle-status branch is the Section 7 dispatch.
- **`flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java`**: Implements the idle-status side of the handler — `processEventTimeIdleStatus`, `tryEmitEventTimeIdleStatus`, `isAllInputIdle`, and the `EventTimeWithIdleStatus.isIdle/setIdleStatus` accessors apply the AND combination across inputs and emit the idle-status watermark when all channels are idle.

---

## Section 9: Generate watermarks by provided WatermarkGeneratorBuilder
*Path: Proposed Changes > Step 2 Generate Watermarks > Generate watermarks by provided WatermarkGeneratorBuilder*
*Classification: Implementable*

> To facilitate the generation and emission of `EventTimeWatermark`s for users, we provide the `WatermarkGeneratorBuilder`. 
>
> In the builder, the user needs to tell us how to get the event time from the record, we denote this behaviour as `EventTimeExtractor`.
>
> ```java
> /** A user function designed to extract event time from an event. */
> @Experimental
> public interface EventTimeExtractor<T> extends Serializable {
>
>     /** Extract the event time from the event, with the result provided in milliseconds. */
>     long extractTimestamp(T event);
> }
> ```
>
> Moreover, we also support three extensions related to watermark creation on builder.
>
>   1. Input Idleness
>
>      1. The builder allows user to set idle status for inputs. If an input has not sent data for a long time, an `IdleStatusWatermark` is generated and sent downstream.
>
>      2. If it is not set, then no `IdleStatusWatermark` will be generated and sent.
>
>   2. Out-of-order time
>
>      1. To accommodate the disorder of input records, user can set a maximum out-of-order time for the `EventTimeWatermark`.
>
>      2. The default value of maximum out-of-order time is 0, which means that the `EventTimeWatermark` will be generated directly from the extracted event time.
>
>   3. Determine when to generate event time watermarks
>
>      1. We support three scenarios regarding the emission of `EventTimeWatermark`s
>
>         1. No `EventTimeWatermark`s are generated and emitted.
>
>         2. `EventTimeWatermark`s are generated and emitted periodically.
>
>         3. `EventTimeWatermark`s are generated and emitted for each event.
>
>      2. By default, we will use scenario 2: periodically generating and emitting `EventTimeWatermark`s, and the periodicity interval is the value of configuration "pipeline.auto-watermark-interval".
>
> Thus, we can give the definition of `WatermarkGeneratorBuilder` as follows.
>
> (Note: For simplicity, the code below only includes the method signatures without the implementation details.)
>
> ```java
> /** A utility class for constructing a processing function that extracts event time
>  * and generates event time watermarks. */
> public class WatermarkGeneratorBuilder<T> {
>
>     // =========  how to extract event times from events =========
>
>     public WatermarkGeneratorBuilder(EventTimeExtractor<T> eventTimeExtractor)
>
>     // =========  generate the event time watermark with what value =========
>
>     public WatermarkGeneratorBuilder<T> withIdleness(Duration idleTimeout)
>
>     public WatermarkGeneratorBuilder<T> withMaxOutOfOrderTime(Duration maxOutOfOrderTime)
>
>     // =========  when to generate event time watermark =========
>
>     public WatermarkGeneratorBuilder<T> noWatermark()
>
>     public WatermarkGeneratorBuilder<T> periodicWatermark()
>
>     public WatermarkGeneratorBuilder<T> periodicWatermark(Duration periodicInterval)
>
>     public WatermarkGeneratorBuilder<T> perEventWatermark()
>
>     // =========  build the watermark generator as process function =========
>     public OneInputStreamProcessFunction<T, T> buildAsProcessFunction()
> }
> ```
>
> Moreover, the `WatermarkGeneratorBuilder` can create a `ProcessFunction` that allows users to extract the event time from each event and generate the corresponding `EventTimeWatermark`.

#### Requirement Summary
This section specifies the `WatermarkGeneratorBuilder` API and the `EventTimeExtractor` interface for generating and emitting event time watermarks. It defines three builder extensions: input idleness (idle status watermark generation), out-of-order time tolerance, and watermark emission strategy (none, periodic, per-event). The PR implements `EventTimeWatermarkGeneratorBuilder` with all three extensions, `EventTimeExtractor` as the functional interface for extracting event time from records, `EventTimeWatermarkStrategy` for the watermark generation strategy, and `ExtractEventTimeProcessFunction` as the generated ProcessFunction that extracts event times and emits watermarks.

**File proportion:** 7/36 files mapped (19.4%) + 1/36 files associated (2.8%) = 8/36 accounted (22.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | Added | +273 / -0 | — | `EventTimeExtension.newWatermarkGeneratorBuilder`, `EventTimeExtension.getEventTimeExtensionImplClass` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeExtractor.java` | Added | +31 / -0 | `EventTimeExtractor` | `EventTimeExtractor.extractTimestamp` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkGeneratorBuilder.java` | Added | +125 / -0 | `EventTimeWatermarkGeneratorBuilder` | `EventTimeWatermarkGeneratorBuilder.EventTimeWatermarkGeneratorBuilder`, `EventTimeWatermarkGeneratorBuilder.withIdleness`, `EventTimeWatermarkGeneratorBuilder.withMaxOutOfOrderTime`, `EventTimeWatermarkGeneratorBuilder.noWatermark`, `EventTimeWatermarkGeneratorBuilder.periodicWatermark`, `EventTimeWatermarkGeneratorBuilder.perEventWatermark`, `EventTimeWatermarkGeneratorBuilder.buildAsProcessFunction`, `EventTimeWatermarkGeneratorBuilder.getEventTimeExtensionImplClass` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkStrategy.java` | Added | +98 / -0 | `EventTimeWatermarkStrategy`, `EventTimeWatermarkGenerateMode` | `EventTimeWatermarkStrategy.EventTimeWatermarkStrategy`, `EventTimeWatermarkStrategy.getEventTimeExtractor`, `EventTimeWatermarkStrategy.getGenerateMode`, `EventTimeWatermarkStrategy.getPeriodicWatermarkInterval`, `EventTimeWatermarkStrategy.getIdleTimeout`, `EventTimeWatermarkStrategy.getMaxOutOfOrderTime` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` | Added | +83 / -0 | — | `EventTimeExtensionImpl.buildAsProcessFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunction.java` | Added | +194 / -0 | `ExtractEventTimeProcessFunction` | `ExtractEventTimeProcessFunction.ExtractEventTimeProcessFunction`, `ExtractEventTimeProcessFunction.initEventTimeExtension`, `ExtractEventTimeProcessFunction.declareWatermarks`, `ExtractEventTimeProcessFunction.processRecord`, `ExtractEventTimeProcessFunction.onProcessingTime`, `ExtractEventTimeProcessFunction.tryEmitEventTimeWatermark` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | Modified | +45 / -1 | — | — |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`**: `newWatermarkGeneratorBuilder` provides the public entry point that returns an `EventTimeWatermarkGeneratorBuilder`, the Section 9 builder API; `getEventTimeExtensionImplClass` resolves the impl class used to construct the builder's ProcessFunction.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeExtractor.java`**: Implements the `EventTimeExtractor` functional interface that allows users to define how to extract event time from records, as specified in the requirement.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkGeneratorBuilder.java`**: Implements the `WatermarkGeneratorBuilder` with methods for configuring input idleness, out-of-order time tolerance, and watermark emission strategy (none, periodic, per-event), matching the three extensions described in the requirement.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkStrategy.java`**: Implements the watermark generation strategy that encapsulates the configuration from the builder, supporting the three emission scenarios (none, periodic, per-event) as specified.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java`**: `buildAsProcessFunction` instantiates the `ExtractEventTimeProcessFunction` from the builder's strategy, completing the Section 9 pipeline from `newWatermarkGeneratorBuilder` to a runtime ProcessFunction.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunction.java`**: Implements the ProcessFunction created by the builder that extracts event time from each event using the `EventTimeExtractor` and generates the corresponding `EventTimeWatermark`, as described in the requirement.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`**: This file's Section 9 row owns no source scope; `ProcessOperator.open` is attributed to Section 12 (per Check 28 tuple uniqueness) because the same changed function both initializes the `ExtractEventTimeProcessFunction` produced by the Section 9 builder and constructs the `EventTimeWrappedOneInputStreamProcessFunction` for Section 12's provided EventTimeProcessFunction. The combined initialization is described under Section 12.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/api/common/eventtime/WatermarksWithIdleness.java` | Modified | +4 / -2 | Exposes the `IdlenessTimer` constructor so the new builder's `withIdleness` path can reuse the existing idle-detection timer rather than reimplementing it; supports the builder idleness option but is not itself the builder API | `IdlenessTimer` | `IdlenessTimer.IdlenessTimer` |

---

## Section 12: Handle watermarks by provided EventTimeProcessFunction
*Path: Proposed Changes > Step 3 Handle Watermarks > Handle watermarks by provided EventTimeProcessFunction*
*Classification: Implementable*

> Before introducing the `EventTimeProcessFunction`, let's first introduce the `EventTimeManager`. This is a key component that allows users to leverage event time within the `EventTimeProcessFunction`. With the `EventTimeManager`, users can access the current event time and create or delete event timers.
>
> ```java
> /**
>  * This utility class allows users to register and delete event timers, as well as retrieve event
>  * times. Note that it is only used in the KeyedProcessFunction.
>  */
> @Experimental
> public interface EventTimeManager {
>     /**
>      * Register an event timer for this process function. The {@code onEventTimer} method will be 
>      * invoked when the event time is reached.
>      *
>      * @param timestamp to trigger timer callback.
>      */
>     void registerTimer(long timestamp);
>
>     /**
>      * Deletes the event-time timer with the given trigger timestamp. This method has only an effect
>      * if such a timer was previously registered and did not already expire.
>      *
>      * @param timestamp indicates the timestamp of the timer to delete.
>      */
>     void deleteTimer(long timestamp);
>
>     /**
>      * Get the current event time.
>      *
>      * @return current event time.
>      */
>     long currentTime();
> }
> ```
>
> We define the `EventTimeProcessFunction` interface to signify that the user intends to utilize event time in the `ProcessFunction`. This includes the ability to be aware of the advance of event time and to register event timers.
>
> ```java
> /**
>  * The base interface for event time process functions, indicating that the process function will
>  * use event time extensions, such as registering event timers and handle event time watermarks.
>  * Note that user-defined process functions should implement this sub-interface rather than this
>  * interface.
>  */
> @Experimental
> public interface EventTimeProcessFunction extends ProcessFunction {
>     void initEventTimeProcessFunction(EventTimeManager eventTimeManager);
> }
> ```
>
> It is important to note that the `EventTimeProcessFunction` is a specialized type of `ProcessFunction`. For each subclass of `ProcessFunction`, we provide corresponding subclasses that support event time extension, e.g. `OneInputStreamProcessFunction` corresponds to `OneInputEventTimeStreamProcessFunction`. 
>
> This means that users creating custom process functions should implement the correspoding `EventTimeProcessFunction` interface if they wish to use event time extension. For example, the `CountNewsClickNumberProcessFunction` in the example implements `OneInputEventTimeStreamProcessFunction` rather than `OneInputStreamProcessFunction`.
>
> ```java
> /** A {@code EventTimeProcessFunction} interface for {@link OneInputStreamProcessFunction}. */
> @Experimental
> public interface OneInputEventTimeStreamProcessFunction<IN, OUT>
>         extends EventTimeProcessFunction, OneInputStreamProcessFunction<IN, OUT> {
>
>     default void onEventTimeWatermark(
>             long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
>             throws Exception {}
>
>     default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
> }
> ```
>
> ```java
> /**
>  * A {@code EventTimeProcessFunction} interface for {@link TwoInputBroadcastStreamProcessFunction}.
>  */
> @Experimental
> public interface TwoInputBroadcastEventTimeStreamProcessFunction<IN1, IN2, OUT>
>         extends EventTimeProcessFunction,
>                 TwoInputBroadcastStreamProcessFunction<IN1, IN2, OUT> {
>
>     default void onEventTimeWatermark(
>             long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
>             throws Exception {}
>
>     default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
> }
> ```
>
> ```java
> /**
>  * A {@code EventTimeProcessFunction} interface for {@link
>  * TwoInputNonBroadcastStreamProcessFunction}.
>  */
> @Experimental
> public interface TwoInputNonBroadcastEventTimeStreamProcessFunction<IN1, IN2, OUT>
>         extends EventTimeProcessFunction,
>                 TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> {
>
>     default void onEventTimeWatermark(
>             long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
>             throws Exception {}
>
>     default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
> }
> ```
>
> ```java
> /** A {@code EventTimeProcessFunction} interface for {@link TwoOutputStreamProcessFunction}. */
> @Experimental
> public interface TwoOutputEventTimeStreamProcessFunction<IN, OUT1, OUT2>
>         extends EventTimeProcessFunction, TwoOutputStreamProcessFunction<IN, OUT1, OUT2> {
>
>     default void onEventTimeWatermark(
>             long watermarkTimestamp,
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputNonPartitionedContext<OUT1, OUT2> ctx)
>             throws Exception {}
>
>     default void onEventTimer(
>             long timestamp,
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputPartitionedContext ctx) {}
> }
> ```
>
> Compared with `ProcessFunction`, `EventTimeProcessFunction` has three more methods.
>
> a. `initEventTimeProcessFunction`
>
> This method enables the `EventTimeProcessFunction` to access some event time extension related components, such as `EventTimeManager` instance.
>
> b. `onEventTimeWatermark`
>
> This method signifies that the `ProcessFunction` has received an `EventTimeWatermark`. It is important to note in `EventTimeProcessFunction`, the `EventTimeWatermark`s will be processed by `EventTimeProcessFunction#onEventTimeWatermark`, whereas other types of watermarks will be processed by the `ProcessFunction#onWatermark`.
>
> c. onEventTimer
>
> This callback method is triggered by the event timer. Within this method, users can access the key and event time associated with the event timer, perform necessary calculations, and output the results.
>
> To utilize the `EventTimeProcessFunction`, users should follow these two steps:
>
>   1. Implement a custom process function by implement one type of `EventTimeProcessFunction`.
>
>   2. Wrap the user-defined process function using `EventTimeUtils#wrapProcessFunction`. This step will provide related components, such as instance of `EventTimeManager`, and will declare the necessary built-in state required for timers, etc.
>
> ```java
> /**
>  * The entry point for the Event Time extension, which provides the following functionality:
>  *
>  * <ul>
>  *   <li>defines the event time watermark.
>  *   <li>provides the {@link WatermarkGeneratorBuilder} to facilitate the generation of
>  *       event time watermarks.
>  *   <li>provides a tool method to encapsulate a user-defined {@link EventTimeProcessFunction} to
>  *       provide the relevant components of the EventTime Extension.
>  * </ul>
>  */
> @Experimental
> public class EventTimeExtension {
>
>     ...
>
>     /**
>      * Wrap the user-defined {@link EventTimeProcessFunction}, which will provide related components
>      * such as {@link EventTimeManager} and declare the necessary built-in state required for the
>      * Timer, etc.
>      */
>     public static <IN, OUT> OneInputStreamProcessFunction<IN, OUT> wrapProcessFunction(
>             OneInputEventTimeStreamProcessFunction<IN, OUT> processFunction) {
>       ...
>     }
> }
> ```

#### Requirement Summary
This section specifies the `EventTimeManager` interface (with methods to access current event time and register/delete event timers), the `EventTimeProcessFunction` interface hierarchy (with `initEventTimeProcessFunction`, `onEventTimeWatermark`, and `onEventTimer` methods), the corresponding subclasses for each ProcessFunction type (e.g., `OneInputEventTimeStreamProcessFunction`), and the `EventTimeExtension#wrapProcessFunction` utility for wrapping user process functions with event time support. The PR implements all of these: the `EventTimeManager` interface and its `DefaultEventTimeManager` implementation, the `EventTimeProcessFunction` base interface with all four subclass variants, the `EventTimeExtension` class with `wrapProcessFunction`, and the wrapper implementations (`EventTimeWrappedOneInputStreamProcessFunction`, etc.) that provide event time components to user functions.

**File proportion:** 21/36 files mapped (58.3%) + 2/36 files associated (5.6%) = 23/36 accounted (63.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | Added | +273 / -0 | — | `EventTimeExtension.wrapProcessFunction` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/EventTimeProcessFunction.java` | Added | +40 / -0 | `EventTimeProcessFunction` | `EventTimeProcessFunction.initEventTimeProcessFunction` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/OneInputEventTimeStreamProcessFunction.java` | Added | +47 / -0 | `OneInputEventTimeStreamProcessFunction` | `OneInputEventTimeStreamProcessFunction.onEventTimeWatermark`, `OneInputEventTimeStreamProcessFunction.onEventTimer` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputBroadcastEventTimeStreamProcessFunction.java` | Added | +47 / -0 | `TwoInputBroadcastEventTimeStreamProcessFunction` | `TwoInputBroadcastEventTimeStreamProcessFunction.onEventTimeWatermark`, `TwoInputBroadcastEventTimeStreamProcessFunction.onEventTimer` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputNonBroadcastEventTimeStreamProcessFunction.java` | Added | +47 / -0 | `TwoInputNonBroadcastEventTimeStreamProcessFunction` | `TwoInputNonBroadcastEventTimeStreamProcessFunction.onEventTimeWatermark`, `TwoInputNonBroadcastEventTimeStreamProcessFunction.onEventTimer` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoOutputEventTimeStreamProcessFunction.java` | Added | +54 / -0 | `TwoOutputEventTimeStreamProcessFunction` | `TwoOutputEventTimeStreamProcessFunction.onEventTimeWatermark`, `TwoOutputEventTimeStreamProcessFunction.onEventTimer` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/timer/EventTimeManager.java` | Added | +53 / -0 | `EventTimeManager` | `EventTimeManager.registerTimer`, `EventTimeManager.deleteTimer`, `EventTimeManager.currentTime` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` | Added | +83 / -0 | `EventTimeExtensionImpl` | `EventTimeExtensionImpl.wrapProcessFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedOneInputStreamProcessFunction.java` | Added | +143 / -0 | `EventTimeWrappedOneInputStreamProcessFunction` | `EventTimeWrappedOneInputStreamProcessFunction.EventTimeWrappedOneInputStreamProcessFunction`, `EventTimeWrappedOneInputStreamProcessFunction.open`, `EventTimeWrappedOneInputStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedOneInputStreamProcessFunction.processRecord`, `EventTimeWrappedOneInputStreamProcessFunction.endInput`, `EventTimeWrappedOneInputStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedOneInputStreamProcessFunction.onWatermark`, `EventTimeWrappedOneInputStreamProcessFunction.onEventTime`, `EventTimeWrappedOneInputStreamProcessFunction.usesStates`, `EventTimeWrappedOneInputStreamProcessFunction.declareWatermarks`, `EventTimeWrappedOneInputStreamProcessFunction.close`, `EventTimeWrappedOneInputStreamProcessFunction.getWrappedUserFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputBroadcastStreamProcessFunction.java` | Added | +180 / -0 | `EventTimeWrappedTwoInputBroadcastStreamProcessFunction` | `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.EventTimeWrappedTwoInputBroadcastStreamProcessFunction`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.open`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.processRecordFromNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.processRecordFromBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.endBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.endNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onWatermarkFromBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onWatermarkFromNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.close`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.usesStates`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.declareWatermarks`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.getWrappedUserFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.java` | Added | +179 / -0 | `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction` | `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.open`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.processRecordFromFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.processRecordFromSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.endFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.endSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onWatermarkFromFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onWatermarkFromSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.close`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.usesStates`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.declareWatermarks`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.getWrappedUserFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoOutputStreamProcessFunction.java` | Added | +156 / -0 | `EventTimeWrappedTwoOutputStreamProcessFunction` | `EventTimeWrappedTwoOutputStreamProcessFunction.EventTimeWrappedTwoOutputStreamProcessFunction`, `EventTimeWrappedTwoOutputStreamProcessFunction.open`, `EventTimeWrappedTwoOutputStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoOutputStreamProcessFunction.processRecord`, `EventTimeWrappedTwoOutputStreamProcessFunction.endInput`, `EventTimeWrappedTwoOutputStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoOutputStreamProcessFunction.onWatermark`, `EventTimeWrappedTwoOutputStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoOutputStreamProcessFunction.usesStates`, `EventTimeWrappedTwoOutputStreamProcessFunction.declareWatermarks`, `EventTimeWrappedTwoOutputStreamProcessFunction.close`, `EventTimeWrappedTwoOutputStreamProcessFunction.getWrappedUserFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/timer/DefaultEventTimeManager.java` | Added | +72 / -0 | `DefaultEventTimeManager` | `DefaultEventTimeManager.DefaultEventTimeManager`, `DefaultEventTimeManager.registerTimer`, `DefaultEventTimeManager.deleteTimer`, `DefaultEventTimeManager.currentTime` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | Modified | +16 / -1 | `KeyedProcessOperator` | `KeyedProcessOperator.onEventTime`, `KeyedProcessOperator.getTimerService`, `KeyedProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java` | Modified | +16 / -1 | `KeyedTwoInputBroadcastProcessOperator` | `KeyedTwoInputBroadcastProcessOperator.onEventTime`, `KeyedTwoInputBroadcastProcessOperator.getTimerService`, `KeyedTwoInputBroadcastProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | Modified | +17 / -1 | `KeyedTwoInputNonBroadcastProcessOperator` | `KeyedTwoInputNonBroadcastProcessOperator.onEventTime`, `KeyedTwoInputNonBroadcastProcessOperator.getTimerService`, `KeyedTwoInputNonBroadcastProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | Modified | +20 / -1 | `KeyedTwoOutputProcessOperator` | `KeyedTwoOutputProcessOperator.onEventTime`, `KeyedTwoOutputProcessOperator.getTimerService`, `KeyedTwoOutputProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | Modified | +45 / -1 | `ProcessOperator` | `ProcessOperator.open`, `ProcessOperator.getProcessorWithKey`, `ProcessOperator.getTimerService`, `ProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java` | Modified | +42 / -2 | `TwoInputBroadcastProcessOperator` | `TwoInputBroadcastProcessOperator.open`, `TwoInputBroadcastProcessOperator.getTimerService`, `TwoInputBroadcastProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java` | Modified | +47 / -2 | `TwoInputNonBroadcastProcessOperator` | `TwoInputNonBroadcastProcessOperator.open`, `TwoInputNonBroadcastProcessOperator.getTimerService`, `TwoInputNonBroadcastProcessOperator.getEventTimeSupplier` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java` | Modified | +34 / -1 | `TwoOutputProcessOperator` | `TwoOutputProcessOperator.open`, `TwoOutputProcessOperator.getTimerService`, `TwoOutputProcessOperator.getEventTimeSupplier` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`**: `wrapProcessFunction` is the public utility specified in Section 12 — it wraps a user-defined `EventTimeProcessFunction` with the appropriate `EventTimeWrapped*StreamProcessFunction`, providing the `EventTimeManager` and declaring the built-in state needed for event timers.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/EventTimeProcessFunction.java`**: Defines the base `EventTimeProcessFunction` interface with the three additional methods: `initEventTimeProcessFunction`, `onEventTimeWatermark`, and `onEventTimer`, as specified in the requirement.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/OneInputEventTimeStreamProcessFunction.java`**: Implements the `OneInputEventTimeStreamProcessFunction` subclass corresponding to `OneInputStreamProcessFunction`, as specified in the requirement's subclass hierarchy.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputBroadcastEventTimeStreamProcessFunction.java`**: Implements the `TwoInputBroadcastEventTimeStreamProcessFunction` subclass for broadcast two-input process functions with event time support.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputNonBroadcastEventTimeStreamProcessFunction.java`**: Implements the `TwoInputNonBroadcastEventTimeStreamProcessFunction` subclass for non-broadcast two-input process functions with event time support.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoOutputEventTimeStreamProcessFunction.java`**: Implements the `TwoOutputEventTimeStreamProcessFunction` subclass for two-output process functions with event time support.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/timer/EventTimeManager.java`**: Implements the `EventTimeManager` interface allowing users to access current event time, register event timers, and delete event timers, as specified in the requirement.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java`**: `wrapProcessFunction` overloads construct the concrete `EventTimeWrapped*` wrappers required by Section 12, handling state declaration and component initialization that delivers `EventTimeManager` to the user function.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedOneInputStreamProcessFunction.java`**: Wraps a `OneInputEventTimeStreamProcessFunction` to provide event time components (EventTimeManager), intercept watermarks for `onEventTimeWatermark` delegation, and handle timer callbacks via `onEventTimer`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputBroadcastStreamProcessFunction.java`**: Wraps a `TwoInputBroadcastEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.java`**: Wraps a `TwoInputNonBroadcastEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoOutputStreamProcessFunction.java`**: Wraps a `TwoOutputEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/timer/DefaultEventTimeManager.java`**: Implements the `EventTimeManager` interface, providing concrete implementations of current event time access, timer registration, and timer deletion using the underlying processing timer service.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java`**: `onEventTime` delegates the event-timer callback to the wrapped `EventTimeProcessFunction`, while `getTimerService` and `getEventTimeSupplier` expose the event-timer service and current-event-time supplier required by `DefaultEventTimeManager` to fulfill Section 12's `EventTimeManager` contract in the keyed one-input operator.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java`**: Same Section 12 event-timer delegation and service access as `KeyedProcessOperator`, for the broadcast keyed two-input operator.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java`**: Same Section 12 event-timer delegation and service access as `KeyedProcessOperator`, for the non-broadcast keyed two-input operator.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java`**: Same Section 12 event-timer delegation and service access as `KeyedProcessOperator`, for the keyed two-output operator.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`**: `open` constructs the `EventTimeWrappedOneInputStreamProcessFunction` around any user-provided `EventTimeProcessFunction` and primes the operator with an event-time-aware processor, which is the Section 12 one-input initialization path (the same function also activates the Section 9 builder's `ExtractEventTimeProcessFunction`, which is the unavoidable coarse function ownership noted under Section 9). `getProcessorWithKey`, `getTimerService`, and `getEventTimeSupplier` expose the event-time services that the wrapped `EventTimeProcessFunction` and its `DefaultEventTimeManager` consume to read current event time and register/delete event timers per Section 12.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java`**: `open` initializes the broadcast wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services Section 12's `EventTimeManager` needs.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java`**: `open` initializes the non-broadcast wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services Section 12's `EventTimeManager` needs.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java`**: `open` initializes the two-output wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services Section 12's `EventTimeManager` needs.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/BroadcastStreamImpl.java` | Modified | +15 / -0 | Updated broadcast stream implementation to support event time extension wrapping when connecting streams | `BroadcastStreamImpl` | `BroadcastStreamImpl.connectAndProcess` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java` | Modified | +31 / -0 | Added utility methods to detect EventTimeProcessFunction instances and apply the wrapping logic during stream construction | `StreamUtils` | `StreamUtils.getOutputTypeForOneInputProcessFunction`, `StreamUtils.getOutputTypeForTwoInputNonBroadcastProcessFunction`, `StreamUtils.getOutputTypeForTwoInputBroadcastProcessFunction`, `StreamUtils.getOutputTypesForTwoOutputProcessFunction` |

---

## Section 13: Handle watermarks by user-defined ProcessFunction
*Path: Proposed Changes > Step 3 Handle Watermarks > Handle watermarks by user-defined ProcessFunction*
*Classification: Implementable*

> Similarly, users can handle event time related watermarks by implementing `ProcessFunction` instead of `EventTimeProcessFunction`. 
>
> In this approach, users must evaluate whether the current watermark received is an `EventTimeWatermark` or `IdleStatusWatermark` within the `ProcessFunction#onWatermark` method and execute the appropriate processing logic accordingly. An example is provided below.
>
> ```java
> public static class CustomProcessFunction
>         implements OneInputStreamProcessFunction<Integer, Integer> {
>
>     @Override
>     public WatermarkHandlingResult onWatermark(
>             Watermark watermark,
>             Collector<Integer> output,
>             NonPartitionedContext<Integer> ctx) throws Exception {
>         if (EventTimeExtension.isEventTimeWatermark(watermark)) {
>             // do something as needed
>             ...
>             return WatermarkHandlingResult.PEEK;
>         } else if (EventTimeExtension.isIdleStatusWatermark(watermark)) {
>             // do something as needed
>             ...
>             return WatermarkHandlingResult.PEEK;
>         } else {
>             // do something as needed
>             ...
>         }
>     }
> }
> ```
>
> It is important to note that when `ProcessFunction#onWatermark` handles event-time relaed watermark, it should return `WatermarkHandlingResult#PEEK`. This indicates that the Flink framework will choose the processing logic based on the watermark definition. For `EventTimeWatermark` and `IdleStatusWatermark`, the Flink framework will forward the watermark downstream.
>
> Conversely, if `ProcessFunction#onWatermark` returns `WatermarkHandlingResult#POP`, the watermarks will not be sent downstream by the Flink framework. Users should be aware that this may result in the loss of the watermark, or they may need to send the watermark manually.

#### Requirement Summary
This section specifies that users can handle event time watermarks directly in `ProcessFunction#onWatermark` by evaluating whether the watermark is an `EventTimeWatermark` or `IdleStatusWatermark`, and describes the `WatermarkHandlingResult#PEEK` vs `WatermarkHandlingResult#POP` behavior for framework-level watermark forwarding. The PR implements this by modifying the operator classes (`ProcessOperator`, `TwoInputBroadcastProcessOperator`, `TwoInputNonBroadcastProcessOperator`, `TwoOutputProcessOperator`) to support the PEEK/POP watermark handling logic, where PEEK delegates to the framework's watermark definition-based processing and POP suppresses downstream forwarding.

**File proportion:** 6/36 files mapped (16.7%) + 0/36 files associated (0.0%) = 6/36 accounted (16.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` | Added | +273 / -0 | — | — |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` | Added | +83 / -0 | — | `EventTimeExtensionImpl.isEventTimeExtensionWatermark` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java` | Modified | +45 / -1 | — | `ProcessOperator.processWatermarkInternal` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java` | Modified | +42 / -2 | — | `TwoInputBroadcastProcessOperator.processWatermark1Internal`, `TwoInputBroadcastProcessOperator.processWatermark2Internal` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java` | Modified | +47 / -2 | — | `TwoInputNonBroadcastProcessOperator.processWatermark1Internal`, `TwoInputNonBroadcastProcessOperator.processWatermark2Internal` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java` | Modified | +34 / -1 | — | `TwoOutputProcessOperator.processWatermarkInternal` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`**: This file's Section 13 row owns no source scope; `EventTimeExtension.isEventTimeWatermark` and `EventTimeExtension.isIdleStatusWatermark` — the predicates the requirement's example code calls inside `ProcessFunction#onWatermark` to branch between event-time, idle-status, and other watermark handling — are attributed to Section 6 and Section 7 respectively (per Check 28 tuple uniqueness), where they define the corresponding watermarks. Section 13 is the consumer of those predicates rather than their owner.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java`**: `isEventTimeExtensionWatermark` backs the public predicates, allowing user-defined `onWatermark` implementations to detect event-time-extension watermarks per Section 13.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`**: `processWatermarkInternal` implements the PEEK/POP watermark handling: when the user's `onWatermark` returns `PEEK`, the framework forwards event-time/idle-status watermarks downstream per Section 13; when it returns `POP`, downstream propagation is suppressed.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java`**: `processWatermark1Internal`/`processWatermark2Internal` apply the same PEEK/POP watermark handling for the broadcast two-input operator per Section 13.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java`**: `processWatermark1Internal`/`processWatermark2Internal` apply the same PEEK/POP watermark handling for the non-broadcast two-input operator per Section 13.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java`**: `processWatermarkInternal` applies the same PEEK/POP watermark handling for the two-output operator per Section 13.

---

## Section 15: Test Plan
*Classification: Implementable*

>  _UT & IT_

#### Requirement Summary
This section specifies that the implementation should include unit tests (UT) and integration tests (IT). The PR implements comprehensive test coverage: `ExtractEventTimeProcessFunctionTest` for unit testing the watermark generation process function, `EventTimeWatermarkCombinerTest` for unit testing the MIN-based combiner logic, `EventTimeWatermarkHandlerTest` for unit testing the watermark handler including idle status, and `EventTimeExtensionITCase` as a full integration test exercising the event time extension end-to-end.

**File proportion:** 0/36 files mapped (0.0%) + 4/36 files associated (11.1%) = 4/36 accounted (11.1%)

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency. The requirement doc has a Test Plan section, so test files are mapped here as associated changes per the mapping rules (test files are associated, not mapped, to evaluation sections).

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/test/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunctionTest.java` | Added | +230 / -0 | Unit tests for the ExtractEventTimeProcessFunction watermark generation logic | — | — |
| `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeExtensionITCase.java` | Added | +848 / -0 | Integration tests exercising the full event time extension end-to-end | — | — |
| `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeWatermarkCombinerTest.java` | Added | +276 / -0 | Unit tests for the EventTimeWatermarkCombiner MIN-based combination logic | — | — |
| `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/eventtime/EventTimeWatermarkHandlerTest.java` | Added | +317 / -0 | Unit tests for the EventTimeWatermarkHandler including idle status watermark handling | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

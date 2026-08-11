# Apache Flink - FLIP-501: Support Window Extension in DataStream V2 API

**PR:** https://github.com/apache/flink/pull/26001
**Requirement Doc:** https://cwiki.apache.org/confluence/display/FLINK/FLIP-501

## Matching Statistics
- **Requirement Doc Coverage:** 6/6 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 30/45 files mapped (66.7%) + 15/45 files associated (33.3%) = 45/45 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | FLIP-501: Support Window Extension in DataStream V2 API | No | N/A | knowledge |
| 2 | Background | No | N/A | knowledge |
| 3 | Example | No | N/A | knowledge |
| 4 | Proposed Changes | No | N/A | knowledge |
| 5 | Proposed Changes > Declare Window | Yes | Yes | implementation |
| 6 | Proposed Changes > Define `WindowProcessFunction` | No | N/A | knowledge |
| 7 | Proposed Changes > Define `WindowProcessFunction` > Lifecycle Methods | Yes | Yes | implementation |
| 8 | Proposed Changes > Define `WindowProcessFunction` > State | Yes | Yes | implementation |
| 9 | Proposed Changes > Define `WindowProcessFunction` > Store and access all records of a window | Yes | Yes | implementation |
| 10 | Proposed Changes > Build a ProcessFunction | Yes | Yes | implementation |
| 11 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 12 | Test Plan | Yes | Yes | evaluation |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `flink-core-api/src/main/java/org/apache/flink/util/TaggedUnion.java` | source | — | Section 5 |
| 2 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/builtin/BuiltinFuncs.java` | source | Section 10 | — |
| 3 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/OneInputWindowContext.java` | source | Section 9 | — |
| 4 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/TwoInputWindowContext.java` | source | Section 9 | — |
| 5 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java` | source | Section 7, Section 8 | — |
| 6 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java` | source | Section 7, Section 9 | — |
| 7 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java` | source | Section 7, Section 9 | — |
| 8 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java` | source | Section 7, Section 9 | — |
| 9 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java` | source | Section 7, Section 8 | — |
| 10 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/GlobalWindowStrategy.java` | source | Section 5 | — |
| 11 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SessionWindowStrategy.java` | source | Section 5 | — |
| 12 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SlidingTimeWindowStrategy.java` | source | Section 5 | — |
| 13 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/TumblingTimeWindowStrategy.java` | source | Section 5 | — |
| 14 | `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/WindowStrategy.java` | source | Section 5 | — |
| 15 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/builtin/BuiltinWindowFuncs.java` | source | Section 10 | — |
| 16 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/join/operators/TwoInputNonBroadcastJoinProcessOperator.java` | source | — | Section 10 |
| 17 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` | source | Section 7, Section 8, Section 9 | — |
| 18 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` | source | Section 7, Section 8, Section 9 | — |
| 19 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowStateStore.java` | source | Section 8 | — |
| 20 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowTriggerContext.java` | source | Section 7 | — |
| 21 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` | source | Section 7, Section 8, Section 10 | — |
| 22 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` | source | Section 7, Section 8, Section 10 | — |
| 23 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` | source | Section 7, Section 8, Section 10 | — |
| 24 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/MergingWindowSet.java` | source | Section 5 | — |
| 25 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | source | Section 5, Section 7, Section 8, Section 9, Section 10 | — |
| 26 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | source | Section 5, Section 7, Section 8, Section 9, Section 10 | — |
| 27 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | source | Section 5, Section 7, Section 8, Section 9, Section 10 | — |
| 28 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java` | source | Section 5, Section 7 | — |
| 29 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedProcessOperator.java` | source | — | Section 10 |
| 30 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedTwoInputNonBroadcastProcessOperator.java` | source | — | Section 10 |
| 31 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedTwoOutputProcessOperator.java` | source | — | Section 10 |
| 32 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | source | — | Section 10 |
| 33 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | source | — | Section 10 |
| 34 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | source | — | Section 10 |
| 35 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/GlobalStreamImpl.java` | source | Section 10 | — |
| 36 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/KeyedPartitionStreamImpl.java` | source | Section 10 | — |
| 37 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/NonKeyedPartitionStreamImpl.java` | source | Section 10 | — |
| 38 | `flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java` | source | Section 10 | — |
| 39 | `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/AbstractAsyncStateStreamOperator.java` | source | — | Section 8 |
| 40 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/datastream/CoGroupedStreams.java` | source | — | Section 5 |
| 41 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/datastream/JoinedStreams.java` | source | — | Section 5 |
| 42 | `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/AbstractStreamOperator.java` | source | — | Section 7 |
| 43 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/datastream/UnionSerializerTest.java` | test | — | Section 5 |
| 44 | `flink-runtime/src/test/java/org/apache/flink/streaming/api/datastream/UnionSerializerUpgradeTest.java` | test | — | Section 5 |
| 45 | `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/window/WindowITCase.java` | test | — | Section 12 |

---

## Section 5: Declare Window
*Path: Proposed Changes > Declare Window*
*Classification: Implementable*

> Users need to first determine which type of Window to use for their applications. We currently provide three built-in window types: Global Window, Time Window, and Session Window.
>
>   * **Global Window** : All the data is in a single window
>
>     * There is only one Global Window, and all data is assigned to this single window.
>
>     * Global Window are suitable for bounded stream scenarios and can be used in GlobalStream, KeyedStream, and NonKeyedStream.
>
>   * **Time Window** : Data within a specific time period is assigned to a single window.
>
>     * Time Windows are divided into multiple windows based on time ranges, and data is assigned to the corresponding window based on its timestamp.
>
>     * We support two types of time windows: tumbling windows and sliding windows. The time semantics within the windows can be divided into event time and processing time.
>
>     * NonKeyedStream is not supported in this FLIP, because the underlying implementation of the window extension relies on states, which is complicated on NonKeyedStream when it comes to job rescaling and state redistribution.
>
>   * **Session Window** : Consecutive data is assigned to a single window.
>
>     * Session windows are a special type of time window and are divided into multiple windows based on time ranges.
>
>     * When data arrives, it is first assigned to the corresponding window based on its timestamp, and then existing windows are merged as much as possible.
>
>     * They are supported only in GlobalStream and KeyedStream. The reason for not supporting NonKeyedStream is the same as for time window.
>
> Users can declare the windows using `WindowStrategy` . To facilitate ease of use, we provide several utility methods for creating `WindowStrategy` .
>
> ```java
> /** The WindowStrategy defines how to generate {@link Window}s in the stream. */
> @Experimental
> public class WindowStrategy {    
>     public static final TimeType PROCESSING_TIME = TimeType.PROCESSING;
>     public static final TimeType EVENT_TIME = TimeType.EVENT;
>
>     /** The types of time used in window operations. */
>     public enum TimeType {
>         PROCESSING,
>         EVENT
>     }
>
>     // ============== global window ================
>
>     /** Creates a global window strategy. */
>     public static WindowStrategy global()
>
>     // ============== tumbling time window ================
>
>     /** Create a tumbling time window strategy and set the window size, 
>     * the {@code timeType} of Window will be set to EVENT, the {@code #allowedLateness} 
>     * of Window will be set to 0. */
>     public static WindowStrategy tumbling(Duration windowSize)
>
>     /** Create a tumbling time window strategy and set the window size and time type, 
>     * the {@code #allowedLateness} of Window will be set to 0. */
>     public static WindowStrategy tumbling(Duration windowSize, TimeType timeType)
>
>     /** Create a tumbling time window strategy and set the window size, time type 
>     * and allowed lateness. */
>     public static WindowStrategy tumbling(Duration windowSize, TimeType timeType, Duration allowedLateness)
>
>     // ============== sliding time window ================
>
>     /** Create a sliding time window strategy and set the window size and slide interval, 
>     * the {@code timeType} of Window will be set to EVENT, the {@code #allowedLateness} 
>     * of Window will be set to 0. */
>     public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval)
>
>     /** Create a sliding time window strategy and set the window size, slide interval 
>     * and time type, the {@code #allowedLateness} of Window will be set to 0. */
>     public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval, TimeType timeType)
>
>     /** Create a sliding time window strategy and set the window size, slide interval, 
>     * time type and allowed lateness. */
>     public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval, TimeType timeType, Duration allowedLateness)
>
>     // ============== session window ================
>
>     /** Create a session window strategy and set the session gap, the {@code timeType} 
>     * of Window will be set to EVENT, the {@code #allowedLateness} of Window will be set to 0. */
>     public static WindowStrategy session(Duration sessionGap)
>
>     /** Create a session window strategy and set the session gap and time type, the default 
>     * {@code #allowedLateness} of Window will be set to 0. */
>     public static WindowStrategy session(Duration sessionGap, TimeType timeType)
>
>     /** Create a session window strategy and set the session gap, time type and allowed lateness. */
>     public static WindowStrategy session(Duration sessionGap, TimeType timeType, Duration allowedLateness)
>
> }
> ```

#### Requirement Summary
This section specifies the three built-in window types (Global, Time/Tumbling/Sliding, Session) and the `WindowStrategy` API for declaring windows. The PR implements the `WindowStrategy` base class with factory methods, along with concrete strategy classes `GlobalWindowStrategy`, `TumblingTimeWindowStrategy`, `SlidingTimeWindowStrategy`, and `SessionWindowStrategy`. The implementation side includes `WindowTriggerContext` for trigger evaluation, `MergingWindowSet` for session window merging, and `WindowUtils` for window assignment and utility logic.

**File proportion:** 10/45 files mapped (22.2%) + 5/45 files associated (11.1%) = 15/45 accounted (33.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/WindowStrategy.java` | Added | +201 / -0 | `WindowStrategy`, `TimeType` | `WindowStrategy.global`, `WindowStrategy.tumbling`, `WindowStrategy.sliding`, `WindowStrategy.session` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/GlobalWindowStrategy.java` | Added | +25 / -0 | `GlobalWindowStrategy` | — |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/TumblingTimeWindowStrategy.java` | Added | +58 / -0 | `TumblingTimeWindowStrategy` | `TumblingTimeWindowStrategy.TumblingTimeWindowStrategy`, `TumblingTimeWindowStrategy.getWindowSize`, `TumblingTimeWindowStrategy.getTimeType`, `TumblingTimeWindowStrategy.getAllowedLateness` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SlidingTimeWindowStrategy.java` | Added | +68 / -0 | `SlidingTimeWindowStrategy` | `SlidingTimeWindowStrategy.SlidingTimeWindowStrategy`, `SlidingTimeWindowStrategy.getWindowSize`, `SlidingTimeWindowStrategy.getWindowSlideInterval`, `SlidingTimeWindowStrategy.getTimeType`, `SlidingTimeWindowStrategy.getAllowedLateness` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SessionWindowStrategy.java` | Added | +47 / -0 | `SessionWindowStrategy` | `SessionWindowStrategy.SessionWindowStrategy`, `SessionWindowStrategy.getSessionGap`, `SessionWindowStrategy.getTimeType` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/MergingWindowSet.java` | Added | +246 / -0 | `MergingWindowSet`, `MergeFunction` | `MergingWindowSet.MergingWindowSet`, `MergingWindowSet.persist`, `MergingWindowSet.getStateWindow`, `MergingWindowSet.retireWindow`, `MergingWindowSet.addWindow`, `MergingWindowSet.merge`, `MergeFunction.merge`, `MergingWindowSet.toString` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java` | Added | +230 / -0 | `WindowUtils` | `WindowUtils.getAllowedLateness`, `WindowUtils.createWindowAssigner`, `WindowUtils.createGlobalWindowAssigner`, `WindowUtils.createTumblingTimeWindowAssigner`, `WindowUtils.createSlidingTimeWindowAssigner`, `WindowUtils.createSessionWindowAssigner` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | Added | +532 / -0 | — | `OneInputWindowProcessOperator.merge`, `OneInputWindowProcessOperator.getMergingWindowSet` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | Added | +763 / -0 | — | `TwoInputNonBroadcastWindowProcessOperator.merge`, `TwoInputNonBroadcastWindowProcessOperator.getMergingWindowSet` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | Added | +549 / -0 | — | `TwoOutputWindowProcessOperator.merge`, `TwoOutputWindowProcessOperator.getMergingWindowSet` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/WindowStrategy.java`**: Defines the base `WindowStrategy` class with factory methods `tumbling()`, `sliding()`, `session()`, and `global()` as specified in the FLIP. Contains configuration for time semantics (event time vs processing time), allowed lateness, and window assignment logic.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/GlobalWindowStrategy.java`**: Implements the Global Window strategy where all data is assigned to a single window, as described for bounded stream scenarios.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/TumblingTimeWindowStrategy.java`**: Implements tumbling time window strategy with configurable duration and time semantics (event time or processing time).
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SlidingTimeWindowStrategy.java`**: Implements sliding time window strategy with configurable window size, slide interval, and time semantics.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SessionWindowStrategy.java`**: Implements session window strategy where consecutive data is grouped, with configurable session gap and window merging behavior.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/MergingWindowSet.java`**: Implements the session window merging logic where "existing windows are merged as much as possible" when data arrives, maintaining the mapping between merged windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java`**: Provides the assigner factory methods (`createWindowAssigner` plus per-strategy `createGlobalWindowAssigner`/`createTumblingTimeWindowAssigner`/`createSlidingTimeWindowAssigner`/`createSessionWindowAssigner`) and `getAllowedLateness`, implementing the window assignment side of declaring a window. (Late-record and cleanup-timer helpers are attributed to Section 7 per their lifecycle role.)
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java`**: The runtime operator's `merge`/`getMergingWindowSet` methods implement session-window merging (declared via `SessionWindowStrategy`) when records arrive at the window operator.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java`**: Same session-window merging behavior for two-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java`**: Same session-window merging behavior for two-output windows.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-core-api/src/main/java/org/apache/flink/util/TaggedUnion.java` | Added | +76 / -0 | Utility class for tagged union types used by the two-input window operator to combine records from two inputs into a single stream for window assignment | `TaggedUnion` | `TaggedUnion.TaggedUnion`, `TaggedUnion.isOne`, `TaggedUnion.isTwo`, `TaggedUnion.getOne`, `TaggedUnion.getTwo`, `TaggedUnion.one`, `TaggedUnion.two`, `TaggedUnion.equals` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/datastream/CoGroupedStreams.java` | Modified | +2 / -52 | Refactored to use the new `TaggedUnion` utility class, replacing the inner `TaggedUnion` class previously defined inline | `CoGroupedStreams`, `TaggedUnion` | `TaggedUnion.TaggedUnion`, `TaggedUnion.isOne`, `TaggedUnion.isTwo`, `TaggedUnion.getOne`, `TaggedUnion.getTwo`, `TaggedUnion.one`, `TaggedUnion.two`, `TaggedUnion.equals` |
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/datastream/JoinedStreams.java` | Modified | +1 / -1 | Import update to reference the extracted `TaggedUnion` class from its new location | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/datastream/UnionSerializerTest.java` | Modified | +1 / -1 | Test import update for the relocated `TaggedUnion` class | — | — |
| `flink-runtime/src/test/java/org/apache/flink/streaming/api/datastream/UnionSerializerUpgradeTest.java` | Modified | +1 / -1 | Test import update for the relocated `TaggedUnion` class | — | — |

---

## Section 7: Lifecycle Methods
*Path: Proposed Changes > Define `WindowProcessFunction` > Lifecycle Methods*
*Classification: Implementable*

> There are four lifecycle methods in the `WindowProcessFunction` . The names and meanings of these methods are as follows:
>
>   1. **onRecord** : `onRecord` indicates that the window has received a record.
>
>   2. **onTrigger** : `onTrigger` indicates that the window has been triggered.
>
>   3. **onClear** : `onClear` indicates that the window has been cleared.
>
>   4. **onLateRecord** : `onLateRecord` indicates that the window has received record after the window is cleared.
>
> There are some important points to consider regarding these methods.
>
>   1. Windows can be triggered multiple times. Therefore, `onRecord` may be called after `onTrigger` .
>
>   2. GlobalWindow is cleared when the data stream ends, while time/session windows are cleared after the window boundary is reached and the `allowedLateness` (see `WindowStrategy` ) has elapsed.
>
>   3. `onLateRecord` method is not possible to access the window state since the window has been cleared.
>
> ```java
> /**
>  * Base interface for functions evaluated over windows, providing callback functions for various
>  * stages of the window's lifecycle.
>  */
> @Experimental
> public interface WindowProcessFunction extends ProcessFunction {
>
>     /**
>      * Explicitly declares states that are bound to the window upfront. Each specific window state
>      * must be declared in this method before it can be used.
>      *
>      * @return all declared window states used by this process function.
>      */
>     default Set<StateDeclaration> useWindowStates() {
>         return Collections.emptySet();
>     }
> }
> ```
>
> ```java
> /**
>  * The {@link WindowContext} interface represents a context for window operations and provides
>  * methods to interact with state that is scoped to the window.
>  */
> @Experimental
> public interface WindowContext {
>
>     /**
>      * Gets the starting timestamp of the window. This is the first timestamp that belongs to this
>      * window.
>      *
>      * @return The starting timestamp of this window, or -1 if the window is not a time window or a
>      *     session window.
>      */
>     long getStartTime();
>
>     /**
>      * Gets the end timestamp of this window. The end timestamp is exclusive, meaning it is the
>      * first timestamp that does not belong to this window any more.
>      *
>      * @return The exclusive end timestamp of this window, or -1 if the window is not a time window
>      *     or a session window.
>      */
>     long getEndTime();
>
>     /**
>      * Retrieves a {@link ListState} object that can be used to interact with fault-tolerant state
>      * that is scoped to the window and key of the current trigger invocation.
>      */
>     <T> Optional<ListState<T>> getWindowState(ListStateDeclaration<T> stateDeclaration)
>             throws Exception;
>
>     /**
>      * Retrieves a {@link MapState} object that can be used to interact with fault-tolerant state
>      * that is scoped to the window and key of the current trigger invocation.
>      */
>     <KEY, V> Optional<MapState<KEY, V>> getWindowState(MapStateDeclaration<KEY, V> stateDeclaration)
>             throws Exception;
>
>     /**
>      * Retrieves a {@link ValueState} object that can be used to interact with fault-tolerant state
>      * that is scoped to the window and key of the current trigger invocation.
>      */
>     <T> Optional<ValueState<T>> getWindowState(ValueStateDeclaration<T> stateDeclaration)
>             throws Exception;
> }
> ```
>
> ```java
> /**
>  * The {@link OneInputWindowContext} interface extends {@link WindowContext} and provides additional
>  * functionality for writing and reading window data.
>  */
> @Experimental
> public interface OneInputWindowContext<IN> extends WindowContext {
>
>     /** Write records into the window's state. */
>     void putRecord(IN record);
>
>     /**
>      * Read records from the window's state, note that this cloud be null if the window is empty.
>      */
>     Iterable<IN> getAllRecords();
> }
> ```
>
> ```java
> /**
>  * The {@link TwoInputWindowContext} interface extends {@link WindowContext} and provides additional
>  * functionality for writing and reading window data.
>  */
> @Experimental
> public interface TwoInputWindowContext<IN1, IN2> extends WindowContext {
>
>     /** Write records from input1 into the window's state. */
>     void putRecord1(IN1 record);
>
>     /**
>      * Read input1's records from the window's state, note that this cloud be null if the window is
>      * empty.
>      */
>     Iterable<IN1> getAllRecords1();
>
>     /** Write records from input2 into the window's state. */
>     void putRecord2(IN2 record);
>
>     /**
>      * Read input2's records from the window's state, note that this cloud be null if the window is
>      * empty.
>      */
>     Iterable<IN2> getAllRecords2();
> }
> ```
>
> ```java
> /**
>  * A type of {@link WindowProcessFunction} that targets one input windows.
>  *
>  * @param <IN> The type of the input value.
>  * @param <OUT> The type of the output value.
>  */
> @Experimental
> public interface OneInputWindowStreamProcessFunction<IN, OUT> extends WindowProcessFunction {
>
>     /**
>      * The {@link #onRecord} method will be invoked when a record is received. Its default behavior
>      * is to store data in built-in window state by {@code WindowContext#putRecord}. If the user
>      * overrides this method, they will need to update the window state as necessary.
>      */
>     default void onRecord(
>             IN record,
>             Collector<OUT> output,
>             PartitionedContext ctx,
>             OneInputWindowContext<IN> windowContext)
>             throws Exception {
>         windowContext.putRecord(record);
>     }
>
>     /**
>      * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
>      * input records in the Window by {@link OneInputWindowContext#getAllRecords()}.
>      */
>     void onTrigger(
>             Collector<OUT> output, PartitionedContext ctx, OneInputWindowContext<IN> windowContext)
>             throws Exception;
>
>     /**
>      * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
>      * {@code windowContext} when the Window expires (the event time or processing time passes its
>      * {@code maxTimestamp} + {@code allowedLateness}).
>      */
>     default void onClear(
>             Collector<OUT> output, PartitionedContext ctx, OneInputWindowContext<IN> windowContext)
>             throws Exception {}
>
>     /**
>      * {@link #onLateRecord} will be invoked when a record is received after the window has been
>      * cleaned.
>      */
>     default void onLateRecord(IN record, Collector<OUT> output, PartitionedContext ctx)
>             throws Exception {}
> }
> ```
>
> ```java
> /**
>  * A type of {@link WindowProcessFunction} that targets two input windows, such as in a join
>  * operation.
>  *
>  * @param <IN1> The type of the input1 value.
>  * @param <IN2> The type of the input2 value.
>  * @param <OUT> The type of the output value.
>  */
> @Experimental
> public interface TwoInputWindowStreamProcessFunction<IN1, IN2, OUT> extends WindowProcessFunction {
>
>     /**
>      * The {@link #onRecord1} method will be invoked when a record is received from input1. Its
>      * default behavior is to store data in built-in window state by {@code
>      * WindowContext#putRecord}. If the user overrides this method, they will need to update the
>      * window state as necessary.
>      */
>     default void onRecord1(
>             IN1 record,
>             Collector<OUT> output,
>             PartitionedContext ctx,
>             TwoInputWindowContext<IN1, IN2> windowContext)
>             throws Exception {
>         windowContext.putRecord1(record);
>     }
>
>     /**
>      * The {@link #onRecord2} method will be invoked when a record is received from input2. Its
>      * default behavior is to store data in built-in window state by {@code
>      * WindowContext#putRecord}. If the user overrides this method, they will need to update the
>      * window state as necessary.
>      */
>     default void onRecord2(
>             IN2 record,
>             Collector<OUT> output,
>             PartitionedContext ctx,
>             TwoInputWindowContext<IN1, IN2> windowContext)
>             throws Exception {
>         windowContext.putRecord2(record);
>     }
>
>     /**
>      * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
>      * input records in the Window by {@link TwoInputWindowContext#getAllRecords1()} and {@link
>      * TwoInputWindowContext#getAllRecords2()}.
>      */
>     void onTrigger(
>             Collector<OUT> output,
>             PartitionedContext ctx,
>             TwoInputWindowContext<IN1, IN2> windowContext)
>             throws Exception;
>
>     /**
>      * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
>      * {@code windowContext} when the Window expires (the event time or processing time passes its
>      * {@code maxTimestamp} + {@code allowedLateness}).
>      */
>     default void onClear(
>             Collector<OUT> output,
>             PartitionedContext ctx,
>             TwoInputWindowContext<IN1, IN2> windowContext)
>             throws Exception {}
>
>     /**
>      * {@link #onLateRecord1} will be invoked when a record is received from input1 after the window
>      * has been cleaned.
>      */
>     default void onLateRecord1(IN1 record, Collector<OUT> output, PartitionedContext ctx)
>             throws Exception {}
>
>     /**
>      * {@link #onLateRecord2} will be invoked when a record is received from input2 after the window
>      * has been cleaned.
>      */
>     default void onLateRecord2(IN1 record, Collector<OUT> output, PartitionedContext ctx)
>             throws Exception {}
> }
> ```
>
> ```java
> /**
>  * A type of {@link WindowProcessFunction} that targets two output windows.
>  *
>  * @param <IN> The type of the input value.
>  * @param <OUT1> The type of the output value to the first output.
>  * @param <OUT2> The type of the output value to the second output.
>  */
> @Experimental
> public interface TwoOutputWindowStreamProcessFunction<IN, OUT1, OUT2>
>         extends WindowProcessFunction {
>
>     /**
>      * The {@link #onRecord} method will be invoked when a record is received. Its default behavior
>      * is to store data in built-in window state by {@code WindowContext#putRecord}. If the user
>      * overrides this method, they will need to update the window state as necessary.
>      */
>     default void onRecord(
>             IN record,
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputPartitionedContext ctx,
>             OneInputWindowContext<IN> windowContext)
>             throws Exception {
>         windowContext.putRecord(record);
>     }
>
>     /**
>      * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
>      * input records in the Window by {@link OneInputWindowContext#getAllRecords()}.
>      */
>     void onTrigger(
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputPartitionedContext ctx,
>             OneInputWindowContext<IN> windowContext)
>             throws Exception;
>
>     /**
>      * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
>      * {@code windowContext} when the Window expires (the event time or processing time passes its
>      * {@code maxTimestamp} + {@code allowedLateness}).
>      */
>     default void onClear(
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputPartitionedContext ctx,
>             OneInputWindowContext<IN> windowContext)
>             throws Exception {}
>
>     /**
>      * {@link #onLateRecord} will be invoked when a record is received after the window has been
>      * cleaned.
>      */
>     default void onLateRecord(
>             IN record,
>             Collector<OUT1> output1,
>             Collector<OUT2> output2,
>             TwoOutputPartitionedContext ctx)
>             throws Exception {}
> }
> ```

#### Requirement Summary
This section specifies the `WindowProcessFunction` interface with four lifecycle methods (`onRecord`, `onTrigger`, `onClear`, `onLateRecord`) and their semantics. The PR implements the base `WindowProcessFunction` interface and its concrete variants for different stream topologies: `OneInputWindowStreamProcessFunction`, `TwoInputNonBroadcastWindowStreamProcessFunction`, and `TwoOutputWindowStreamProcessFunction`. The corresponding internal implementations and runtime operators drive the lifecycle by invoking these methods at the appropriate phases of window processing.

**File proportion:** 15/45 files mapped (33.3%) + 1/45 files associated (2.2%) = 16/45 accounted (35.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java` | Added | +44 / -0 | `WindowProcessFunction` | — |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java` | Added | +94 / -0 | — | `WindowContext.getStartTime`, `WindowContext.getEndTime` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java` | Added | +73 / -0 | `OneInputWindowStreamProcessFunction` | `OneInputWindowStreamProcessFunction.onTrigger`, `OneInputWindowStreamProcessFunction.onClear`, `OneInputWindowStreamProcessFunction.onLateRecord` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java` | Added | +100 / -0 | `TwoInputNonBroadcastWindowStreamProcessFunction` | `TwoInputNonBroadcastWindowStreamProcessFunction.onTrigger`, `TwoInputNonBroadcastWindowStreamProcessFunction.onClear`, `TwoInputNonBroadcastWindowStreamProcessFunction.onLateRecord1`, `TwoInputNonBroadcastWindowStreamProcessFunction.onLateRecord2` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java` | Added | +82 / -0 | `TwoOutputWindowStreamProcessFunction` | `TwoOutputWindowStreamProcessFunction.onTrigger`, `TwoOutputWindowStreamProcessFunction.onClear`, `TwoOutputWindowStreamProcessFunction.onLateRecord` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` | Added | +139 / -0 | — | `DefaultOneInputWindowContext.getStartTime`, `DefaultOneInputWindowContext.getEndTime` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` | Added | +155 / -0 | — | `DefaultTwoInputWindowContext.getStartTime`, `DefaultTwoInputWindowContext.getEndTime` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowTriggerContext.java` | Added | +190 / -0 | `WindowTriggerContext` | `WindowTriggerContext.WindowTriggerContext`, `WindowTriggerContext.getMetricGroup`, `WindowTriggerContext.getCurrentWatermark`, `WindowTriggerContext.getPartitionedState`, `WindowTriggerContext.mergePartitionedState`, `WindowTriggerContext.getCurrentProcessingTime`, `WindowTriggerContext.registerProcessingTimeTimer`, `WindowTriggerContext.registerEventTimeTimer`, `WindowTriggerContext.deleteProcessingTimeTimer`, `WindowTriggerContext.deleteEventTimeTimer`, `WindowTriggerContext.onElement`, `WindowTriggerContext.onProcessingTime`, `WindowTriggerContext.onEventTime`, `WindowTriggerContext.onMerge`, `WindowTriggerContext.clear`, `WindowTriggerContext.toString`, `WindowTriggerContext.setKey`, `WindowTriggerContext.setWindow`, `WindowTriggerContext.getKey`, `WindowTriggerContext.getWindow` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` | Added | +109 / -0 | — | `InternalOneInputWindowStreamProcessFunction.processRecord` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` | Added | +120 / -0 | — | `InternalTwoInputWindowStreamProcessFunction.processRecordFromFirstInput`, `InternalTwoInputWindowStreamProcessFunction.processRecordFromSecondInput` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` | Added | +114 / -0 | — | `InternalTwoOutputWindowStreamProcessFunction.processRecord` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | Added | +532 / -0 | `OneInputWindowProcessOperator` | `OneInputWindowProcessOperator.open`, `OneInputWindowProcessOperator.getCurrentProcessingTime`, `OneInputWindowProcessOperator.close`, `OneInputWindowProcessOperator.processElement`, `OneInputWindowProcessOperator.onEventTime`, `OneInputWindowProcessOperator.onProcessingTime`, `OneInputWindowProcessOperator.getProcessingTimeManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | Added | +763 / -0 | `TwoInputNonBroadcastWindowProcessOperator` | `TwoInputNonBroadcastWindowProcessOperator.open`, `TwoInputNonBroadcastWindowProcessOperator.getCurrentProcessingTime`, `TwoInputNonBroadcastWindowProcessOperator.processElement1`, `TwoInputNonBroadcastWindowProcessOperator.processElement2`, `TwoInputNonBroadcastWindowProcessOperator.onEventTime`, `TwoInputNonBroadcastWindowProcessOperator.onProcessingTime`, `TwoInputNonBroadcastWindowProcessOperator.getProcessingTimeManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | Added | +549 / -0 | `TwoOutputWindowProcessOperator` | `TwoOutputWindowProcessOperator.open`, `TwoOutputWindowProcessOperator.getCurrentProcessingTime`, `TwoOutputWindowProcessOperator.close`, `TwoOutputWindowProcessOperator.processElement`, `TwoOutputWindowProcessOperator.onEventTime`, `TwoOutputWindowProcessOperator.onProcessingTime`, `TwoOutputWindowProcessOperator.getProcessingTimeManager` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java` | Added | +230 / -0 | — | `WindowUtils.isWindowLate`, `WindowUtils.isElementLate`, `WindowUtils.deleteCleanupTimer`, `WindowUtils.registerCleanupTimer`, `WindowUtils.cleanupTime`, `WindowUtils.isCleanupTime` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java`**: Declares the base `WindowProcessFunction` interface that holds the four lifecycle methods (`onRecord`, `onTrigger`, `onClear`, `onLateRecord`) implemented in the concrete subclasses below. (The `useWindowStates` declaration method is attributed to Section 8 per its requirement narrative.)
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java`**: `getStartTime`/`getEndTime` expose the window boundaries that lifecycle callbacks consult to decide trigger/clear timing.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java`**: Concrete `WindowProcessFunction` lifecycle methods (`onTrigger`, `onClear`, `onLateRecord`) for single-input streams; `onRecord` is attributed to Section 9 per its built-in record-storage default.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java`**: Concrete lifecycle methods (`onTrigger`, `onClear`, `onLateRecord1`/`onLateRecord2`) for two-input non-broadcast streams.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java`**: Concrete lifecycle methods (`onTrigger`, `onClear`, `onLateRecord`) for two-output streams.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java`**: `getStartTime`/`getEndTime` accessors return the underlying window's time bounds for lifecycle callbacks.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java`**: Same time-accessor behavior for two-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowTriggerContext.java`**: Drives the trigger lifecycle: `onElement`, `onProcessingTime`, `onEventTime`, `onMerge`, `clear`, and the supporting timer/state-access plumbing (`registerEventTimeTimer`/`deleteEventTimeTimer`/`registerProcessingTimeTimer`/`deleteProcessingTimeTimer`/`getPartitionedState`/`mergePartitionedState`/`getCurrentWatermark`/`getCurrentProcessingTime`/`getMetricGroup`/`setKey`/`setWindow`/`getKey`/`getWindow`/`toString`) — all lifecycle/trigger mechanics rather than declaration.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java`**: `processRecord` dispatches inbound records to the user's `onRecord` lifecycle hook.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java`**: `processRecordFromFirstInput`/`processRecordFromSecondInput` dispatch per-input records to `onRecord1`/`onRecord2` lifecycle hooks.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java`**: `processRecord` dispatches inbound records to the user's two-output `onRecord` lifecycle hook.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java`**: Lifecycle plumbing — `open`/`close` for setup/teardown, `processElement` to feed records through trigger/lifecycle dispatch, `onEventTime`/`onProcessingTime` to fire triggers, and `getCurrentProcessingTime`/`getProcessingTimeManager` for timing support.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java`**: Same lifecycle plumbing for two-input windows with dual `processElement1`/`processElement2`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java`**: Same lifecycle plumbing for two-output windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java`**: `isWindowLate`/`isElementLate`/`registerCleanupTimer`/`deleteCleanupTimer`/`cleanupTime`/`isCleanupTime` implement the late-record check and cleanup-timer behavior that drives `onClear` and `onLateRecord` lifecycle handling.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/AbstractStreamOperator.java` | Modified | +1 / -1 | Method visibility change to allow window process operators to access base operator internals | `AbstractStreamOperator` | `AbstractStreamOperator.getPartitionedState` |

---

## Section 8: State
*Path: Proposed Changes > Define `WindowProcessFunction` > State*
*Classification: Implementable*

> In a window, there are two types of states: partitioned state and window state.
>
> 1) **Partitioned State** : We refer to the partition-related state as partitioned state.
>
>   * For NonKeyedStream, this state is shared among a specific task.
>
>   * For KeyedStream, this state is shared among data with the same key.
>
>   * User can declare partitioned state through `ProcessFunction#usesStates` and use partitioned state through `PartitionedContext#getStateManager` .
>
>   * It's users' responsibility to clear data in partitioned state that are no longer needed in `onClear` .
>
> 2) **Window State** : We refer to the window-related state as window state.
>
>   * Window state is bound to a specific window. For example, the window state declared and used for the same key in the 10:00-11:00 window is different from that in the 11:00-12:00 window.
>
>   * User can declare window state through `WindowProcessFunction#usesWindowStates` and use window state through `WindowContext#getWindowState` .
>
>   * All window state will eventually be cleared by framework, whether or not the user clears it manually in `onClear` .

#### Requirement Summary
This section specifies the two types of state in a window: partitioned state (shared per task or per key) and window state (bound to a specific window instance). The PR implements the `WindowContext` interface with `getWindowState` for accessing window-scoped state, the `OneInputWindowContext` and `TwoInputWindowContext` variants with their default implementations, and the `WindowStateStore` that manages the underlying state storage scoped to individual windows.

**File proportion:** 11/45 files mapped (24.4%) + 1/45 files associated (2.2%) = 12/45 accounted (26.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java` | Added | +44 / -0 | — | `WindowProcessFunction.useWindowStates` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java` | Added | +94 / -0 | `WindowContext` | `WindowContext.getWindowState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowStateStore.java` | Added | +264 / -0 | `WindowStateStore` | `WindowStateStore.WindowStateStore`, `WindowStateStore.isStateDeclared`, `WindowStateStore.stateRedistributionModeIsNotNone`, `WindowStateStore.getWindowState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` | Added | +139 / -0 | — | `DefaultOneInputWindowContext.getWindowState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` | Added | +155 / -0 | — | `DefaultTwoInputWindowContext.getWindowState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` | Added | +109 / -0 | — | `InternalOneInputWindowStreamProcessFunction.usesStates` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` | Added | +120 / -0 | — | `InternalTwoInputWindowStreamProcessFunction.usesStates` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` | Added | +114 / -0 | — | `InternalTwoOutputWindowStreamProcessFunction.usesStates` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | Added | +532 / -0 | — | `OneInputWindowProcessOperator.clearAllState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | Added | +763 / -0 | — | `TwoInputNonBroadcastWindowProcessOperator.clearAllState` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | Added | +549 / -0 | — | `TwoOutputWindowProcessOperator.clearAllState` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java`**: Declares `useWindowStates()`, the API specified in this section for users to register window state declarations alongside their `WindowProcessFunction`.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java`**: `getWindowState` provides the window-scoped state access required by this section. (`getStartTime`/`getEndTime` go to Section 7 as lifecycle context APIs; `putRecord`/`getAllRecords` are not defined on `WindowContext`.)
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowStateStore.java`**: Implements the window state storage mechanism that scopes state to individual window instances. Manages state declaration via `usesWindowStates`, state access via namespaced keys, and automatic cleanup of window state when the window is cleared by the framework.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java`**: `getWindowState` integrates `WindowStateStore` with the runtime state backend for single-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java`**: `getWindowState` integrates `WindowStateStore` with the runtime state backend for two-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java`**: `usesStates` propagates the user's window-state declarations from `WindowProcessFunction#useWindowStates` so the runtime can register them.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java`**: Same `usesStates` propagation for two-input window functions.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java`**: Same `usesStates` propagation for two-output window functions.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java`**: `clearAllState` releases the window-scoped state when the window is cleared by the framework.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java`**: Same window-state cleanup for two-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java`**: Same window-state cleanup for two-output windows.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-runtime/src/main/java/org/apache/flink/runtime/asyncprocessing/operators/AbstractAsyncStateStreamOperator.java` | Modified | +1 / -1 | Method visibility change to allow window state access via `WindowStateStore` and default contexts | `AbstractAsyncStateStreamOperator` | `AbstractAsyncStateStreamOperator.getOrCreateKeyedState` |

---

## Section 9: Store and access all records of a window
*Path: Proposed Changes > Define `WindowProcessFunction` > Store and access all records of a window*
*Classification: Implementable*

> We provide built-in window state for each window to store the input data. Users can access this through `WindowContext#putRecord` and `WindowContext#getAllRecords`. This state will be cleared when the window is cleared.
>
> By default, `onRecord` stores the received data in the window's built-in state by `WindowContext#putRecord` , and users can retrieve all the data within the window using `WindowContext#getAllRecords` .
>
> Therefore, when overriding `onRecord`, users should consider whether they need to write the input data into the built-in state. A typical example is if users want to do pre-aggregation, they can declare a window reduce/aggregate state, perform aggregation in `onRecord`, update the aggregated window state, and output the final result in `onTrigger` . Therefore, unnecessary cost of caching all data are eliminated.

#### Requirement Summary
This section specifies the built-in record storage mechanism within windows, where `WindowContext#putRecord` stores input data and `WindowContext#getAllRecords` retrieves it, with default `onRecord` behavior storing records automatically. The PR implements `putRecord` and `getAllRecords` in `WindowContext` and its implementations, and the `DefaultTwoInputWindowContext` additionally provides per-input record access.

**File proportion:** 10/45 files mapped (22.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/OneInputWindowContext.java` | Added | +45 / -0 | `OneInputWindowContext` | `OneInputWindowContext.putRecord`, `OneInputWindowContext.getAllRecords` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/TwoInputWindowContext.java` | Added | +57 / -0 | `TwoInputWindowContext` | `TwoInputWindowContext.putRecord1`, `TwoInputWindowContext.getAllRecords1`, `TwoInputWindowContext.putRecord2`, `TwoInputWindowContext.getAllRecords2` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java` | Added | +73 / -0 | — | `OneInputWindowStreamProcessFunction.onRecord` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java` | Added | +100 / -0 | — | `TwoInputNonBroadcastWindowStreamProcessFunction.onRecord1`, `TwoInputNonBroadcastWindowStreamProcessFunction.onRecord2` |
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java` | Added | +82 / -0 | — | `TwoOutputWindowStreamProcessFunction.onRecord` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` | Added | +139 / -0 | `DefaultOneInputWindowContext` | `DefaultOneInputWindowContext.DefaultOneInputWindowContext`, `DefaultOneInputWindowContext.setWindow`, `DefaultOneInputWindowContext.putRecord`, `DefaultOneInputWindowContext.getAllRecords` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` | Added | +155 / -0 | `DefaultTwoInputWindowContext` | `DefaultTwoInputWindowContext.DefaultTwoInputWindowContext`, `DefaultTwoInputWindowContext.setWindow`, `DefaultTwoInputWindowContext.putRecord1`, `DefaultTwoInputWindowContext.getAllRecords1`, `DefaultTwoInputWindowContext.putRecord2`, `DefaultTwoInputWindowContext.getAllRecords2` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | Added | +532 / -0 | — | `OneInputWindowProcessOperator.emitWindowContents` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | Added | +763 / -0 | — | `TwoInputNonBroadcastWindowProcessOperator.emitWindowContents` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | Added | +549 / -0 | — | `TwoOutputWindowProcessOperator.emitWindowContents` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/OneInputWindowContext.java`**: Declares `putRecord`/`getAllRecords`, the built-in record storage API specified in this section for single-input windows.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/TwoInputWindowContext.java`**: Declares per-input `putRecord1`/`putRecord2` and `getAllRecords1`/`getAllRecords2`, the built-in record storage API for two-input windows.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java`**: The default `onRecord` implementation stores records via `windowContext.putRecord(record)`, directly implementing the built-in record-storage default specified by this section.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java`**: The default `onRecord1`/`onRecord2` implementations store per-input records via `windowContext.putRecord1`/`putRecord2`, implementing the same built-in behavior for two-input windows.
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java`**: The default `onRecord` implementation stores records via `windowContext.putRecord(record)` for two-output windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java`**: Constructor/`setWindow` lifecycle methods position the context against the current window before `putRecord`/`getAllRecords` persist and retrieve records from the window-scoped state, backed by `WindowStateStore`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java`**: Same per-input record storage for two-input windows via `putRecord1`/`putRecord2` and `getAllRecords1`/`getAllRecords2`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java`**: `emitWindowContents` reads accumulated records from the built-in window record store and drives the `onTrigger` emission flow.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java`**: `emitWindowContents` performs the same per-input record retrieval and emission flow for two-input windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java`**: `emitWindowContents` performs the same record retrieval and emission for two-output windows.

---

## Section 10: Build a ProcessFunction
*Path: Proposed Changes > Build a ProcessFunction*
*Classification: Implementable*

> After declaring the Window and defining the `WindowProcessFunction` , users have to encapsulate these two components into a `ProcessFunction` . As shown below, users can use the `BuiltinFuncs.window` method to transform the `WindowStrategy` and the `WindowProcessFunction` into a `ProcessFunction` .
>
> ```java
> /** Built-in functions for all extension of datastream v2. */
> @Experimental
> public final class BuiltinFuncs {
>
>     ...
>
>     /**
>      * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
>      * operation.
>      */
>     public static <IN, OUT> OneInputStreamProcessFunction<IN, OUT> window(
>                 WindowStrategy windowStrategy,
>                 OneInputWindowStreamProcessFunction<IN, OUT> windowProcessFunction)
>
>     /**
>     * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
>     * operation.
>     */
>     public static <IN1, IN2, OUT> TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> window(
>                 WindowStrategy windowStrategy,
>                 TwoInputWindowStreamProcessFunction<IN1, IN2, OUT> windowProcessFunction)
>
>   /**
>     * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
>     * operation.
>     */
>     public static <IN, OUT1, OUT2> TwoOutputStreamProcessFunction<IN, OUT1, OUT2> window(
>                 WindowStrategy windowStrategy,
>                 TwoOutputWindowStreamProcessFunction<IN, OUT1, OUT2> windowProcessFunction)
>
> }
> ```
>
> Users can integrate the encapsulated `ProcessFunction` into the data processing stream using the `DataStream#process` or `DataStream#connectAndProcess` methods.

#### Requirement Summary
This section specifies the `BuiltinFuncs.window` method that combines a `WindowStrategy` and `WindowProcessFunction` into a `ProcessFunction`, and the integration with `DataStream#process` and `DataStream#connectAndProcess`. The PR implements the `BuiltinFuncs.window` factory methods, the `BuiltinWindowFuncs` backend that creates the appropriate window process operators, the stream implementations (`GlobalStreamImpl`, `KeyedPartitionStreamImpl`, `NonKeyedPartitionStreamImpl`) that wire window-based process functions into the stream pipeline, and `StreamUtils` helper methods for operator construction.

**File proportion:** 12/45 files mapped (26.7%) + 7/45 files associated (15.6%) = 19/45 accounted (42.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/builtin/BuiltinFuncs.java` | Modified | +91 / -0 | `BuiltinFuncs` | `BuiltinFuncs.window` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/builtin/BuiltinWindowFuncs.java` | Added | +94 / -0 | `BuiltinWindowFuncs` | `BuiltinWindowFuncs.window` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/GlobalStreamImpl.java` | Modified | +85 / -26 | `GlobalStreamImpl` | `GlobalStreamImpl.process`, `GlobalStreamImpl.connectAndProcess` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/KeyedPartitionStreamImpl.java` | Modified | +110 / -31 | `KeyedPartitionStreamImpl` | `KeyedPartitionStreamImpl.process`, `KeyedPartitionStreamImpl.connectAndProcess` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/NonKeyedPartitionStreamImpl.java` | Modified | +94 / -17 | `NonKeyedPartitionStreamImpl` | `NonKeyedPartitionStreamImpl.process`, `NonKeyedPartitionStreamImpl.connectAndProcess` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java` | Modified | +224 / -0 | `StreamUtils` | `StreamUtils.getOutputTypeForOneInputProcessFunction`, `StreamUtils.getOutputTypeForTwoInputNonBroadcastProcessFunction`, `StreamUtils.getOutputTypesForTwoOutputProcessFunction`, `StreamUtils.getTwoInputTransformation`, `StreamUtils.transformOneInputWindow`, `StreamUtils.transformTwoInputNonBroadcastWindow`, `StreamUtils.transformTwoOutputWindow` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` | Added | +109 / -0 | `InternalOneInputWindowStreamProcessFunction` | `InternalOneInputWindowStreamProcessFunction.InternalOneInputWindowStreamProcessFunction`, `InternalOneInputWindowStreamProcessFunction.getAssigner`, `InternalOneInputWindowStreamProcessFunction.getTrigger`, `InternalOneInputWindowStreamProcessFunction.getAllowedLateness`, `InternalOneInputWindowStreamProcessFunction.getWindowStrategy`, `InternalOneInputWindowStreamProcessFunction.getWindowProcessFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` | Added | +120 / -0 | `InternalTwoInputWindowStreamProcessFunction` | `InternalTwoInputWindowStreamProcessFunction.InternalTwoInputWindowStreamProcessFunction`, `InternalTwoInputWindowStreamProcessFunction.getAssigner`, `InternalTwoInputWindowStreamProcessFunction.getTrigger`, `InternalTwoInputWindowStreamProcessFunction.getAllowedLateness`, `InternalTwoInputWindowStreamProcessFunction.getWindowStrategy`, `InternalTwoInputWindowStreamProcessFunction.getWindowProcessFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` | Added | +114 / -0 | `InternalTwoOutputWindowStreamProcessFunction` | `InternalTwoOutputWindowStreamProcessFunction.InternalTwoOutputWindowStreamProcessFunction`, `InternalTwoOutputWindowStreamProcessFunction.getAssigner`, `InternalTwoOutputWindowStreamProcessFunction.getTrigger`, `InternalTwoOutputWindowStreamProcessFunction.getAllowedLateness`, `InternalTwoOutputWindowStreamProcessFunction.getWindowStrategy`, `InternalTwoOutputWindowStreamProcessFunction.getWindowProcessFunction` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` | Added | +532 / -0 | — | `OneInputWindowProcessOperator.OneInputWindowProcessOperator` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` | Added | +763 / -0 | — | `TwoInputNonBroadcastWindowProcessOperator.TwoInputNonBroadcastWindowProcessOperator` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` | Added | +549 / -0 | — | `TwoOutputWindowProcessOperator.TwoOutputWindowProcessOperator` |

#### Modification Summary
- **`flink-datastream-api/src/main/java/org/apache/flink/datastream/api/builtin/BuiltinFuncs.java`**: Adds the `window()` factory methods that transform a `WindowStrategy` and `WindowProcessFunction` into a `ProcessFunction`, exactly as specified in the FLIP. Provides overloads for one-input, two-input, and two-output variants.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/builtin/BuiltinWindowFuncs.java`**: Backend implementation of `BuiltinFuncs.window` that constructs the appropriate internal window stream process functions and wires them with the provided window strategy.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/GlobalStreamImpl.java`**: Extends the GlobalStream implementation to detect window-based process functions from `BuiltinFuncs.window` and route them to the appropriate window process operators instead of regular process operators.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/KeyedPartitionStreamImpl.java`**: Extends the KeyedPartitionStream implementation with window support, detecting window process functions and creating window process operators for `process` and `connectAndProcess` calls.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/NonKeyedPartitionStreamImpl.java`**: Extends the NonKeyedPartitionStream implementation with window support for global windows (time/session windows are excluded per the FLIP specification).
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java`**: Adds utility methods for creating window process operators, resolving window strategies, and constructing the stream transformations needed to integrate window operators into the DataStream pipeline.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java`**: Constructor and assigner/trigger/strategy/process-function accessors that `BuiltinFuncs.window` uses to wrap a `WindowStrategy` and user `WindowProcessFunction` into the returned `ProcessFunction`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java`**: Same wrapper-construction accessors for two-input window functions.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java`**: Same wrapper-construction accessors for two-output window functions.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java`**: Constructor that the stream implementations instantiate to integrate the window strategy/function into the runtime operator returned as a `ProcessFunction`.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java`**: Same construction integration for two-input non-broadcast windows.
- **`flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java`**: Same construction integration for two-output windows.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/join/operators/TwoInputNonBroadcastJoinProcessOperator.java` | Modified | +1 / -1 | Import update due to refactoring of base operator class hierarchy to support window operators | — | — |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedProcessOperator.java` | Added | +96 / -0 | Base class extracted from `KeyedProcessOperator` to share common keyed operator logic between regular and window process operators | `BaseKeyedProcessOperator` | `BaseKeyedProcessOperator.BaseKeyedProcessOperator`, `BaseKeyedProcessOperator.open`, `BaseKeyedProcessOperator.getOutputCollector`, `BaseKeyedProcessOperator.currentKey`, `BaseKeyedProcessOperator.getNonPartitionedContext`, `BaseKeyedProcessOperator.setKeyContextElement1`, `BaseKeyedProcessOperator.isAsyncStateProcessingEnabled` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedTwoInputNonBroadcastProcessOperator.java` | Added | +109 / -0 | Base class extracted from `KeyedTwoInputNonBroadcastProcessOperator` to share common logic with the two-input window operator | `BaseKeyedTwoInputNonBroadcastProcessOperator` | `BaseKeyedTwoInputNonBroadcastProcessOperator.BaseKeyedTwoInputNonBroadcastProcessOperator`, `BaseKeyedTwoInputNonBroadcastProcessOperator.open`, `BaseKeyedTwoInputNonBroadcastProcessOperator.getOutputCollector`, `BaseKeyedTwoInputNonBroadcastProcessOperator.currentKey`, `BaseKeyedTwoInputNonBroadcastProcessOperator.getNonPartitionedContext`, `BaseKeyedTwoInputNonBroadcastProcessOperator.setKeyContextElement1`, `BaseKeyedTwoInputNonBroadcastProcessOperator.setKeyContextElement2`, `BaseKeyedTwoInputNonBroadcastProcessOperator.isAsyncStateProcessingEnabled` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/BaseKeyedTwoOutputProcessOperator.java` | Added | +118 / -0 | Base class extracted from `KeyedTwoOutputProcessOperator` to share common logic with the two-output window operator | `BaseKeyedTwoOutputProcessOperator` | `BaseKeyedTwoOutputProcessOperator.BaseKeyedTwoOutputProcessOperator`, `BaseKeyedTwoOutputProcessOperator.open`, `BaseKeyedTwoOutputProcessOperator.getMainCollector`, `BaseKeyedTwoOutputProcessOperator.getSideCollector`, `BaseKeyedTwoOutputProcessOperator.currentKey`, `BaseKeyedTwoOutputProcessOperator.getNonPartitionedContext`, `BaseKeyedTwoOutputProcessOperator.setKeyContextElement1`, `BaseKeyedTwoOutputProcessOperator.isAsyncStateProcessingEnabled` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java` | Modified | +2 / -54 | Refactored to extend `BaseKeyedProcessOperator`, extracting common logic into the base class | `KeyedProcessOperator` | `KeyedProcessOperator.KeyedProcessOperator`, `KeyedProcessOperator.open`, `KeyedProcessOperator.getOutputCollector`, `KeyedProcessOperator.currentKey`, `KeyedProcessOperator.getNonPartitionedContext`, `KeyedProcessOperator.setKeyContextElement1`, `KeyedProcessOperator.isAsyncStateProcessingEnabled` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java` | Modified | +2 / -61 | Refactored to extend `BaseKeyedTwoInputNonBroadcastProcessOperator`, extracting common logic into the base class | `KeyedTwoInputNonBroadcastProcessOperator` | `KeyedTwoInputNonBroadcastProcessOperator.KeyedTwoInputNonBroadcastProcessOperator`, `KeyedTwoInputNonBroadcastProcessOperator.open`, `KeyedTwoInputNonBroadcastProcessOperator.getOutputCollector`, `KeyedTwoInputNonBroadcastProcessOperator.currentKey`, `KeyedTwoInputNonBroadcastProcessOperator.getNonPartitionedContext`, `KeyedTwoInputNonBroadcastProcessOperator.setKeyContextElement1`, `KeyedTwoInputNonBroadcastProcessOperator.setKeyContextElement2`, `KeyedTwoInputNonBroadcastProcessOperator.isAsyncStateProcessingEnabled` |
| `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java` | Modified | +2 / -70 | Refactored to extend `BaseKeyedTwoOutputProcessOperator`, extracting common logic into the base class | `KeyedTwoOutputProcessOperator` | `KeyedTwoOutputProcessOperator.KeyedTwoOutputProcessOperator`, `KeyedTwoOutputProcessOperator.open`, `KeyedTwoOutputProcessOperator.getMainCollector`, `KeyedTwoOutputProcessOperator.getSideCollector`, `KeyedTwoOutputProcessOperator.currentKey`, `KeyedTwoOutputProcessOperator.getNonPartitionedContext`, `KeyedTwoOutputProcessOperator.setKeyContextElement1`, `KeyedTwoOutputProcessOperator.isAsyncStateProcessingEnabled` |

---

## Section 12: Test Plan
*Path: Test Plan*
*Classification: Implementable*

>  _UT & IT_

#### Requirement Summary
This section specifies that the FLIP will be validated through unit tests (UT) and integration tests (IT). The PR fulfills this by adding `WindowITCase`, a comprehensive integration test that exercises the full window extension end-to-end across the supported window types (global, tumbling, sliding, session) and stream topologies (one-input, two-input non-broadcast, two-output) introduced by this FLIP.

**File proportion:** 0/45 files mapped (0.0%) + 1/45 files associated (2.2%) = 1/45 accounted (2.2%)

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency. The Test Plan section only states "UT & IT" without specifying particular test files; the integration test is associated rather than direct-mapped per the plan's test-file rule.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-tests/src/test/java/org/apache/flink/test/streaming/api/datastream/extension/window/WindowITCase.java` | Added | +620 / -0 | Integration tests that validate the window extension end-to-end across the supported window types and stream topologies, fulfilling the FLIP's "UT & IT" plan | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

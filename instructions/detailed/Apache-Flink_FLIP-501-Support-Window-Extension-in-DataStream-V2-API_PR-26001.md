> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# FLIP-501: Support Window Extension in DataStream V2 API

# Background

Window are at the heart of processing infinite streams. Window split the stream into "buckets" of finite size, over which we can apply computations. For example, time windows are used to aggregate data within specific time intervals.

The goal of this FLIP is to provide Window extension for DataStream V2, thereby enhancing its data processing capabilities and usability.

# Example

Before diving into the details, let's explore an example of how to use Window extension on DataStream V2 to statistic popular products with sales exceeding 10,000 in an e-commerce platform within each hour.

```java
public static class Order {
    private long orderId;
    private long productId;
    private long userId;
    private long orderTime;
}

public static class PopularProduct {
    private long productId;
    private long numberOfSales;
}

public static void main(String[] args) throws Exception {
    ExecutionEnvironment env = ExecutionEnvironment.getInstance();

    NonKeyedPartitionStream<Order> orderStream =
            createSourceWithEvenTimeWatermarkGenerator(env);

    NonKeyedPartitionStream<PopularProduct> popularProductStream =
            orderStream
                    .keyBy(Order::getProductId)
                    .process(
                            BuiltinFuncs.window(
                                    WindowStrategy.tumbling(Duration.ofHours(1)),
                                    new StatisticPopularProductWindowProcessFunction()
                            )
                    );

    popularProductStream.toSink(new WrappedSink<>(new PrintSink<>()));
    env.execute("StatisticPopularProductExample");
}
```

In this example, users need to complete the following steps:

1) Repartition by product ID

Since we want to determine whether each product is popular, we need to repartition the order data by product ID. The subsequent computational logic will be based on this.

2) Declare the Window to be used

We aim to aggregate results within each hour, so we declare a tumbling window with a duration of one hour (defaulting to event time).

```java
                            BuiltinFuncs.window(
                                    // create tumbling window with widow size 1 hour
                                    WindowStrategy.tumbling(Duration.ofHours(1)),
                                    new StatisticPopularProductWindowProcessFunction()
                            )
```

3) Declare the window state for storing product sales counts

To accumulate the sales counts of products, we declare a window state in the `StatisticPopularProductWindowProcessFunction` to store the sales counts of each product.

```java
        private ValueStateDeclaration<Long> productSaleCountDeclaration;

        @Override
        public Set<StateDeclaration> useWindowStates() {
            // declare state to store the number of sales for product
            productSaleCountDeclaration =
                    StateDeclarations.valueState("product-sale-count-state", TypeDescriptors.LONG);
            return Set.of(productSaleCountDeclaration);
        }
```

4) When receiving order data, increment the product sales count

Upon receiving order data, we use the declared window state to retrieve and update the product sales count.

```java
        @Override
        public void onRecord(
                Order order,
                Collector<PopularProduct> output,
                PartitionedContext ctx,
                OneInputWindowContext<Order> windowContext)
                throws Exception {
            // increment the number of sales for product
            ValueState<Long> productSaleCountState =
                    windowContext.getWindowState(productSaleCountDeclaration).get();
            productSaleCountState.update(productSaleCountState.value() + 1);
        }
```

5) When the Window triggers, determine if the product sales count meets the popularity threshold

When the window triggers, first retrieve the product ID and sales count, then determine if it qualifies as a popular product. If it does, output the information of the popular product.

```java
        @Override
        public void onTrigger(
                Collector<PopularProduct> output,
                PartitionedContext ctx,
                OneInputWindowContext<Order> windowContext)
                throws Exception {
            // get current productId and number of sales
            long productId = ctx.getStateManager().getCurrentKey();
            Long saleCount =
                    windowContext.getWindowState(productSaleCountDeclaration).get().value();

            // determine if the product is a popular product,
            // and if so, output
            if (saleCount > POPULAR_PRODUCT_NUM_THRESHOLD) {
                output.collect(new PopularProduct(productId, saleCount));
            }
        }
```

6) When the Window is cleared, remove the window state storing the product sales count.

```java
        @Override
        public void onClear(
                Collector<PopularProduct> output,
                PartitionedContext ctx,
                OneInputWindowContext<Order> windowContext) throws Exception {
            windowContext.getWindowState(productSaleCountDeclaration).ifPresent(State::clear);
        }
```

# Proposed Changes

The processing logic of a window typically involves the following three steps:

  1. When data arrives, it is assigned to the corresponding one or more windows.

  2. When data arrives or time updates, determine if the window trigger conditions are met.

  3. When data arrives or the window triggers, perform the corresponding computational logic.

Essentially, a window is a special type of `ProcessFunction` . In order to achieve the above three steps, it is usually necessary to use state to cache window data. Additionally, in FLIP-499, we provided support for event time, allowing users to more easily implement windows with event time semantics. To simplify the user experience with windows, this FLIP also provides support for window-related functionalities through extension.

When using the window extension provided by this FLIP, users need to complete the following three steps:

  1. Declare Window

     * Define the type of window, the algorithm for assigning data to the window, and the trigger conditions. For example, declare a tumbling time window with a duration of one hour.

  2. Define `WindowProcessFunction`

     * Specify the logic that needs to be executed at various phases of the window's lifecycle.

  3. Combine Window Declaration and `WindowProcessFunction` to Build a `ProcessFunction`

     * Encapsulate the window declaration and `WindowProcessFunction` into a `ProcessFunction` , which can then be used in the DataStream V2 Stream API. The framework will handle the declaration of the state and timer required for caching window data, eliminating the need for users to manage these aspects themselves.

The following sections will provide a detailed explanation of each of these steps.

## Declare Window

Users need to first determine which type of Window to use for their applications. We currently provide three built-in window types: Global Window, Time Window, and Session Window.

  * **Global Window** : All the data is in a single window

    * There is only one Global Window, and all data is assigned to this single window.

    * Global Window are suitable for bounded stream scenarios and can be used in GlobalStream, KeyedStream, and NonKeyedStream.

  * **Time Window** : Data within a specific time period is assigned to a single window.

    * Time Windows are divided into multiple windows based on time ranges, and data is assigned to the corresponding window based on its timestamp.

    * We support two types of time windows: tumbling windows and sliding windows. The time semantics within the windows can be divided into event time and processing time.

    * NonKeyedStream is not supported in this FLIP, because the underlying implementation of the window extension relies on states, which is complicated on NonKeyedStream when it comes to job rescaling and state redistribution. Applying such a time window to a non-keyed stream is rejected with an `IllegalStateException`.

  * **Session Window** : Consecutive data is assigned to a single window.

    * Session windows are a special type of time window and are divided into multiple windows based on time ranges.

    * When data arrives, it is first assigned to the corresponding window based on its timestamp, and then existing windows are merged as much as possible.

    * They are supported only in GlobalStream and KeyedStream. The reason for not supporting NonKeyedStream is the same as for time window.

Users can declare the windows using `WindowStrategy` . To facilitate ease of use, we provide several utility methods for creating `WindowStrategy` .

```java
/** The WindowStrategy defines how to generate {@link Window}s in the stream. */
@Experimental
public class WindowStrategy {    
    public static final TimeType PROCESSING_TIME = TimeType.PROCESSING;
    public static final TimeType EVENT_TIME = TimeType.EVENT;

    /** The types of time used in window operations. */
    public enum TimeType {
        PROCESSING,
        EVENT
    }

    // ============== global window ================
    
    /** Creates a global window strategy. */
    public static WindowStrategy global()
    
    // ============== tumbling time window ================
      
    /** Create a tumbling time window strategy and set the window size, 
    * the {@code timeType} of Window will be set to EVENT, the {@code #allowedLateness} 
    * of Window will be set to 0. */
    public static WindowStrategy tumbling(Duration windowSize)
    
    /** Create a tumbling time window strategy and set the window size and time type, 
    * the {@code #allowedLateness} of Window will be set to 0. */
    public static WindowStrategy tumbling(Duration windowSize, TimeType timeType)
    
    /** Create a tumbling time window strategy and set the window size, time type 
    * and allowed lateness. */
    public static WindowStrategy tumbling(Duration windowSize, TimeType timeType, Duration allowedLateness)
    
    // ============== sliding time window ================
      
    /** Create a sliding time window strategy and set the window size and slide interval, 
    * the {@code timeType} of Window will be set to EVENT, the {@code #allowedLateness} 
    * of Window will be set to 0. */
    public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval)
    
    /** Create a sliding time window strategy and set the window size, slide interval 
    * and time type, the {@code #allowedLateness} of Window will be set to 0. */
    public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval, TimeType timeType)
    
    /** Create a sliding time window strategy and set the window size, slide interval, 
    * time type and allowed lateness. */
    public static WindowStrategy sliding(Duration windowSize, Duration windowSlideInterval, TimeType timeType, Duration allowedLateness)
    
    // ============== session window ================
    
    /** Create a session window strategy and set the session gap, the {@code timeType} 
    * of Window will be set to EVENT, the {@code #allowedLateness} of Window will be set to 0. */
    public static WindowStrategy session(Duration sessionGap)
    
    /** Create a session window strategy and set the session gap and time type, the default 
    * {@code #allowedLateness} of Window will be set to 0. */
    public static WindowStrategy session(Duration sessionGap, TimeType timeType)
    
    /** Create a session window strategy and set the session gap, time type and allowed lateness. */
    public static WindowStrategy session(Duration sessionGap, TimeType timeType, Duration allowedLateness)

}
```


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/WindowStrategy.java` defining `WindowStrategy` and `TimeType` with functions `WindowStrategy.global`, `WindowStrategy.tumbling`, `WindowStrategy.sliding`, and `WindowStrategy.session`. Defines the base `WindowStrategy` class with factory methods `tumbling`, `sliding`, `session`, and `global` as specified in the FLIP. Contains configuration for time semantics (event time vs processing time), allowed lateness, and window assignment logic.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/GlobalWindowStrategy.java` defining `GlobalWindowStrategy`. Implements the Global Window strategy where all data is assigned to a single window, as described for bounded stream scenarios.

3. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/TumblingTimeWindowStrategy.java` defining `TumblingTimeWindowStrategy` with functions `TumblingTimeWindowStrategy.TumblingTimeWindowStrategy`, `TumblingTimeWindowStrategy.getWindowSize`, `TumblingTimeWindowStrategy.getTimeType`, and `TumblingTimeWindowStrategy.getAllowedLateness`. Implements tumbling time window strategy with configurable duration and time semantics (event time or processing time).

4. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SlidingTimeWindowStrategy.java` defining `SlidingTimeWindowStrategy` with functions `SlidingTimeWindowStrategy.SlidingTimeWindowStrategy`, `SlidingTimeWindowStrategy.getWindowSize`, `SlidingTimeWindowStrategy.getWindowSlideInterval`, `SlidingTimeWindowStrategy.getTimeType`, and `SlidingTimeWindowStrategy.getAllowedLateness`. Implements sliding time window strategy with configurable window size, slide interval, and time semantics.

5. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/strategy/SessionWindowStrategy.java` defining `SessionWindowStrategy` with functions `SessionWindowStrategy.SessionWindowStrategy`, `SessionWindowStrategy.getSessionGap`, and `SessionWindowStrategy.getTimeType`. Implements session window strategy where consecutive data is grouped, with configurable session gap and window merging behavior.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/MergingWindowSet.java` defining `MergingWindowSet` and `MergeFunction` with functions `MergingWindowSet.MergingWindowSet`, `MergingWindowSet.persist`, `MergingWindowSet.getStateWindow`, `MergingWindowSet.retireWindow`, `MergingWindowSet.addWindow`, `MergingWindowSet.merge`, `MergeFunction.merge`, and `MergingWindowSet.toString`. Implements the session window merging logic where "existing windows are merged as much as possible" when data arrives, maintaining the mapping between merged windows.

7. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java` defining `WindowUtils` with functions `WindowUtils.getAllowedLateness`, `WindowUtils.createWindowAssigner`, `WindowUtils.createGlobalWindowAssigner`, `WindowUtils.createTumblingTimeWindowAssigner`, `WindowUtils.createSlidingTimeWindowAssigner`, and `WindowUtils.createSessionWindowAssigner`. Provides the assigner factory methods (`createWindowAssigner` plus per-strategy `createGlobalWindowAssigner`/`createTumblingTimeWindowAssigner`/`createSlidingTimeWindowAssigner`/`createSessionWindowAssigner`) and `getAllowedLateness`, implementing the window assignment side of declaring a window.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` defining functions `OneInputWindowProcessOperator.merge` and `OneInputWindowProcessOperator.getMergingWindowSet`. The runtime operator's `merge`/`getMergingWindowSet` methods implement session-window merging (declared via `SessionWindowStrategy`) when records arrive at the window operator.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` defining functions `TwoInputNonBroadcastWindowProcessOperator.merge` and `TwoInputNonBroadcastWindowProcessOperator.getMergingWindowSet`. Same session-window merging behavior for two-input windows.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` defining functions `TwoOutputWindowProcessOperator.merge` and `TwoOutputWindowProcessOperator.getMergingWindowSet`. Same session-window merging behavior for two-output windows.
## Define `WindowProcessFunction`

After declaring a window, users need to define the operational logic for various stages of the window's lifecycle, called `WindowProcessFunction` in this FLIP.

### Lifecycle Methods

There are four lifecycle methods in the `WindowProcessFunction` . The names and meanings of these methods are as follows:

  1. **onRecord** : `onRecord` indicates that the window has received a record.

  2. **onTrigger** : `onTrigger` indicates that the window has been triggered.

  3. **onClear** : `onClear` indicates that the window has been cleared.

  4. **onLateRecord** : `onLateRecord` indicates that the window has received record after the window is cleared.

There are some important points to consider regarding these methods.

  1. Windows can be triggered multiple times. Therefore, `onRecord` may be called after `onTrigger` .

  2. GlobalWindow is cleared when the data stream ends, while time/session windows are cleared after the window boundary is reached and the `allowedLateness` (see `WindowStrategy` ) has elapsed.

  3. `onLateRecord` method is not possible to access the window state since the window has been cleared.

```java
/**
 * Base interface for functions evaluated over windows, providing callback functions for various
 * stages of the window's lifecycle.
 */
@Experimental
public interface WindowProcessFunction extends ProcessFunction {

    /**
     * Explicitly declares states that are bound to the window upfront. Each specific window state
     * must be declared in this method before it can be used.
     *
     * @return all declared window states used by this process function.
     */
    default Set<StateDeclaration> useWindowStates() {
        return Collections.emptySet();
    }
}
```

```java
/**
 * The {@link WindowContext} interface represents a context for window operations and provides
 * methods to interact with state that is scoped to the window.
 */
@Experimental
public interface WindowContext {
  
    /**
     * Gets the starting timestamp of the window. This is the first timestamp that belongs to this
     * window.
     *
     * @return The starting timestamp of this window, or -1 if the window is not a time window or a
     *     session window.
     */
    long getStartTime();

    /**
     * Gets the end timestamp of this window. The end timestamp is exclusive, meaning it is the
     * first timestamp that does not belong to this window any more.
     *
     * @return The exclusive end timestamp of this window, or -1 if the window is not a time window
     *     or a session window.
     */
    long getEndTime();

    /**
     * Retrieves a {@link ListState} object that can be used to interact with fault-tolerant state
     * that is scoped to the window and key of the current trigger invocation.
     */
    <T> Optional<ListState<T>> getWindowState(ListStateDeclaration<T> stateDeclaration)
            throws Exception;

    /**
     * Retrieves a {@link MapState} object that can be used to interact with fault-tolerant state
     * that is scoped to the window and key of the current trigger invocation.
     */
    <KEY, V> Optional<MapState<KEY, V>> getWindowState(MapStateDeclaration<KEY, V> stateDeclaration)
            throws Exception;

    /**
     * Retrieves a {@link ValueState} object that can be used to interact with fault-tolerant state
     * that is scoped to the window and key of the current trigger invocation.
     */
    <T> Optional<ValueState<T>> getWindowState(ValueStateDeclaration<T> stateDeclaration)
            throws Exception;
}
```

```java
/**
 * The {@link OneInputWindowContext} interface extends {@link WindowContext} and provides additional
 * functionality for writing and reading window data.
 */
@Experimental
public interface OneInputWindowContext<IN> extends WindowContext {

    /** Write records into the window's state. */
    void putRecord(IN record);

    /**
     * Read records from the window's state, note that this cloud be null if the window is empty.
     */
    Iterable<IN> getAllRecords();
}
```

```java
/**
 * The {@link TwoInputWindowContext} interface extends {@link WindowContext} and provides additional
 * functionality for writing and reading window data.
 */
@Experimental
public interface TwoInputWindowContext<IN1, IN2> extends WindowContext {

    /** Write records from input1 into the window's state. */
    void putRecord1(IN1 record);

    /**
     * Read input1's records from the window's state, note that this cloud be null if the window is
     * empty.
     */
    Iterable<IN1> getAllRecords1();

    /** Write records from input2 into the window's state. */
    void putRecord2(IN2 record);

    /**
     * Read input2's records from the window's state, note that this cloud be null if the window is
     * empty.
     */
    Iterable<IN2> getAllRecords2();
}
```

```java
/**
 * A type of {@link WindowProcessFunction} that targets one input windows.
 *
 * @param <IN> The type of the input value.
 * @param <OUT> The type of the output value.
 */
@Experimental
public interface OneInputWindowStreamProcessFunction<IN, OUT> extends WindowProcessFunction {

    /**
     * The {@link #onRecord} method will be invoked when a record is received. Its default behavior
     * is to store data in built-in window state by {@code WindowContext#putRecord}. If the user
     * overrides this method, they will need to update the window state as necessary.
     */
    default void onRecord(
            IN record,
            Collector<OUT> output,
            PartitionedContext ctx,
            OneInputWindowContext<IN> windowContext)
            throws Exception {
        windowContext.putRecord(record);
    }

    /**
     * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
     * input records in the Window by {@link OneInputWindowContext#getAllRecords()}.
     */
    void onTrigger(
            Collector<OUT> output, PartitionedContext ctx, OneInputWindowContext<IN> windowContext)
            throws Exception;

    /**
     * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
     * {@code windowContext} when the Window expires (the event time or processing time passes its
     * {@code maxTimestamp} + {@code allowedLateness}).
     */
    default void onClear(
            Collector<OUT> output, PartitionedContext ctx, OneInputWindowContext<IN> windowContext)
            throws Exception {}

    /**
     * {@link #onLateRecord} will be invoked when a record is received after the window has been
     * cleaned.
     */
    default void onLateRecord(IN record, Collector<OUT> output, PartitionedContext ctx)
            throws Exception {}
}
```

```java
/**
 * A type of {@link WindowProcessFunction} that targets two input windows, such as in a join
 * operation.
 *
 * @param <IN1> The type of the input1 value.
 * @param <IN2> The type of the input2 value.
 * @param <OUT> The type of the output value.
 */
@Experimental
public interface TwoInputNonBroadcastWindowStreamProcessFunction<IN1, IN2, OUT> extends WindowProcessFunction {

    /**
     * The {@link #onRecord1} method will be invoked when a record is received from input1. Its
     * default behavior is to store data in built-in window state by {@code
     * WindowContext#putRecord}. If the user overrides this method, they will need to update the
     * window state as necessary.
     */
    default void onRecord1(
            IN1 record,
            Collector<OUT> output,
            PartitionedContext ctx,
            TwoInputWindowContext<IN1, IN2> windowContext)
            throws Exception {
        windowContext.putRecord1(record);
    }

    /**
     * The {@link #onRecord2} method will be invoked when a record is received from input2. Its
     * default behavior is to store data in built-in window state by {@code
     * WindowContext#putRecord}. If the user overrides this method, they will need to update the
     * window state as necessary.
     */
    default void onRecord2(
            IN2 record,
            Collector<OUT> output,
            PartitionedContext ctx,
            TwoInputWindowContext<IN1, IN2> windowContext)
            throws Exception {
        windowContext.putRecord2(record);
    }

    /**
     * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
     * input records in the Window by {@link TwoInputWindowContext#getAllRecords1()} and {@link
     * TwoInputWindowContext#getAllRecords2()}.
     */
    void onTrigger(
            Collector<OUT> output,
            PartitionedContext ctx,
            TwoInputWindowContext<IN1, IN2> windowContext)
            throws Exception;

    /**
     * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
     * {@code windowContext} when the Window expires (the event time or processing time passes its
     * {@code maxTimestamp} + {@code allowedLateness}).
     */
    default void onClear(
            Collector<OUT> output,
            PartitionedContext ctx,
            TwoInputWindowContext<IN1, IN2> windowContext)
            throws Exception {}

    /**
     * {@link #onLateRecord1} will be invoked when a record is received from input1 after the window
     * has been cleaned.
     */
    default void onLateRecord1(IN1 record, Collector<OUT> output, PartitionedContext ctx)
            throws Exception {}

    /**
     * {@link #onLateRecord2} will be invoked when a record is received from input2 after the window
     * has been cleaned.
     */
    default void onLateRecord2(IN1 record, Collector<OUT> output, PartitionedContext ctx)
            throws Exception {}
}
```

```java
/**
 * A type of {@link WindowProcessFunction} that targets two output windows.
 *
 * @param <IN> The type of the input value.
 * @param <OUT1> The type of the output value to the first output.
 * @param <OUT2> The type of the output value to the second output.
 */
@Experimental
public interface TwoOutputWindowStreamProcessFunction<IN, OUT1, OUT2>
        extends WindowProcessFunction {

    /**
     * The {@link #onRecord} method will be invoked when a record is received. Its default behavior
     * is to store data in built-in window state by {@code WindowContext#putRecord}. If the user
     * overrides this method, they will need to update the window state as necessary.
     */
    default void onRecord(
            IN record,
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputPartitionedContext ctx,
            OneInputWindowContext<IN> windowContext)
            throws Exception {
        windowContext.putRecord(record);
    }

    /**
     * The {@link #onTrigger} will be invoked when the Window is triggered, you can obtain all the
     * input records in the Window by {@link OneInputWindowContext#getAllRecords()}.
     */
    void onTrigger(
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputPartitionedContext ctx,
            OneInputWindowContext<IN> windowContext)
            throws Exception;

    /**
     * Callback when a window is about to be cleaned up. It is the time to deletes any state in the
     * {@code windowContext} when the Window expires (the event time or processing time passes its
     * {@code maxTimestamp} + {@code allowedLateness}).
     */
    default void onClear(
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputPartitionedContext ctx,
            OneInputWindowContext<IN> windowContext)
            throws Exception {}

    /**
     * {@link #onLateRecord} will be invoked when a record is received after the window has been
     * cleaned.
     */
    default void onLateRecord(
            IN record,
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputPartitionedContext ctx)
            throws Exception {}
}
```


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java` defining `WindowProcessFunction`. Declares the base `WindowProcessFunction` interface that holds the four lifecycle methods (`onRecord`, `onTrigger`, `onClear`, `onLateRecord`) implemented in the concrete subclasses below.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java` defining functions `WindowContext.getStartTime` and `WindowContext.getEndTime`. `getStartTime`/`getEndTime` expose the window boundaries that lifecycle callbacks consult to decide trigger/clear timing.

3. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java` defining `OneInputWindowStreamProcessFunction` with functions `OneInputWindowStreamProcessFunction.onTrigger`, `OneInputWindowStreamProcessFunction.onClear`, and `OneInputWindowStreamProcessFunction.onLateRecord`.

4. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java` defining `TwoInputNonBroadcastWindowStreamProcessFunction` with functions `TwoInputNonBroadcastWindowStreamProcessFunction.onTrigger`, `TwoInputNonBroadcastWindowStreamProcessFunction.onClear`, `TwoInputNonBroadcastWindowStreamProcessFunction.onLateRecord1`, and `TwoInputNonBroadcastWindowStreamProcessFunction.onLateRecord2`. Concrete lifecycle methods (`onTrigger`, `onClear`, `onLateRecord1`/`onLateRecord2`) for two-input non-broadcast streams.

5. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java` defining `TwoOutputWindowStreamProcessFunction` with functions `TwoOutputWindowStreamProcessFunction.onTrigger`, `TwoOutputWindowStreamProcessFunction.onClear`, and `TwoOutputWindowStreamProcessFunction.onLateRecord`. Concrete lifecycle methods (`onTrigger`, `onClear`, `onLateRecord`) for two-output streams.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` defining functions `DefaultOneInputWindowContext.getStartTime` and `DefaultOneInputWindowContext.getEndTime`. `getStartTime`/`getEndTime` accessors return the underlying window's time bounds for lifecycle callbacks.

7. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` defining functions `DefaultTwoInputWindowContext.getStartTime` and `DefaultTwoInputWindowContext.getEndTime`. Same time-accessor behavior for two-input windows.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowTriggerContext.java` defining `WindowTriggerContext` with functions `WindowTriggerContext.WindowTriggerContext`, `WindowTriggerContext.getMetricGroup`, `WindowTriggerContext.getCurrentWatermark`, `WindowTriggerContext.getPartitionedState`, `WindowTriggerContext.mergePartitionedState`, `WindowTriggerContext.getCurrentProcessingTime`, `WindowTriggerContext.registerProcessingTimeTimer`, `WindowTriggerContext.registerEventTimeTimer`, `WindowTriggerContext.deleteProcessingTimeTimer`, `WindowTriggerContext.deleteEventTimeTimer`, `WindowTriggerContext.onElement`, `WindowTriggerContext.onProcessingTime`, `WindowTriggerContext.onEventTime`, `WindowTriggerContext.onMerge`, `WindowTriggerContext.clear`, `WindowTriggerContext.toString`, `WindowTriggerContext.setKey`, `WindowTriggerContext.setWindow`, `WindowTriggerContext.getKey`, and `WindowTriggerContext.getWindow`. Drives the trigger lifecycle: `onElement`, `onProcessingTime`, `onEventTime`, `onMerge`, `clear`, and the supporting timer/state-access plumbing (`registerEventTimeTimer`/`deleteEventTimeTimer`/`registerProcessingTimeTimer`/`deleteProcessingTimeTimer`/`getPartitionedState`/`mergePartitionedState`/`getCurrentWatermark`/`getCurrentProcessingTime`/`getMetricGroup`/`setKey`/`setWindow`/`getKey`/`getWindow`/`toString`) — all lifecycle/trigger mechanics rather than declaration.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` defining functions `InternalOneInputWindowStreamProcessFunction.processRecord`. `processRecord` dispatches inbound records to the user's `onRecord` lifecycle hook.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` defining functions `InternalTwoInputWindowStreamProcessFunction.processRecordFromFirstInput` and `InternalTwoInputWindowStreamProcessFunction.processRecordFromSecondInput`. `processRecordFromFirstInput`/`processRecordFromSecondInput` dispatch per-input records to `onRecord1`/`onRecord2` lifecycle hooks.

11. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` defining functions `InternalTwoOutputWindowStreamProcessFunction.processRecord`. `processRecord` dispatches inbound records to the user's two-output `onRecord` lifecycle hook.

12. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` defining `OneInputWindowProcessOperator` with functions `OneInputWindowProcessOperator.open`, `OneInputWindowProcessOperator.getCurrentProcessingTime`, `OneInputWindowProcessOperator.close`, `OneInputWindowProcessOperator.processElement`, `OneInputWindowProcessOperator.onEventTime`, `OneInputWindowProcessOperator.onProcessingTime`, and `OneInputWindowProcessOperator.getProcessingTimeManager`. Lifecycle plumbing — `open`/`close` for setup/teardown, `processElement` to feed records through trigger/lifecycle dispatch, `onEventTime`/`onProcessingTime` to fire triggers, and `getCurrentProcessingTime`/`getProcessingTimeManager` for timing support.

13. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` defining `TwoInputNonBroadcastWindowProcessOperator` with functions `TwoInputNonBroadcastWindowProcessOperator.open`, `TwoInputNonBroadcastWindowProcessOperator.getCurrentProcessingTime`, `TwoInputNonBroadcastWindowProcessOperator.processElement1`, `TwoInputNonBroadcastWindowProcessOperator.processElement2`, `TwoInputNonBroadcastWindowProcessOperator.onEventTime`, `TwoInputNonBroadcastWindowProcessOperator.onProcessingTime`, and `TwoInputNonBroadcastWindowProcessOperator.getProcessingTimeManager`. Same lifecycle plumbing for two-input windows with dual `processElement1`/`processElement2`.

14. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` defining `TwoOutputWindowProcessOperator` with functions `TwoOutputWindowProcessOperator.open`, `TwoOutputWindowProcessOperator.getCurrentProcessingTime`, `TwoOutputWindowProcessOperator.close`, `TwoOutputWindowProcessOperator.processElement`, `TwoOutputWindowProcessOperator.onEventTime`, `TwoOutputWindowProcessOperator.onProcessingTime`, and `TwoOutputWindowProcessOperator.getProcessingTimeManager`. Same lifecycle plumbing for two-output windows.

15. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/utils/WindowUtils.java` defining functions `WindowUtils.isWindowLate`, `WindowUtils.isElementLate`, `WindowUtils.deleteCleanupTimer`, `WindowUtils.registerCleanupTimer`, `WindowUtils.cleanupTime`, and `WindowUtils.isCleanupTime`. `isWindowLate`/`isElementLate`/`registerCleanupTimer`/`deleteCleanupTimer`/`cleanupTime`/`isCleanupTime` implement the late-record check and cleanup-timer behavior that drives `onClear` and `onLateRecord` lifecycle handling.
### State

In a window, there are two types of states: partitioned state and window state.

1) **Partitioned State** : We refer to the partition-related state as partitioned state.

  * For NonKeyedStream, this state is shared among a specific task.

  * For KeyedStream, this state is shared among data with the same key.

  * User can declare partitioned state through `ProcessFunction#usesStates` and use partitioned state through `PartitionedContext#getStateManager` .

  * It's users' responsibility to clear data in partitioned state that are no longer needed in `onClear` .

2) **Window State** : We refer to the window-related state as window state.

  * Window state is bound to a specific window. For example, the window state declared and used for the same key in the 10:00-11:00 window is different from that in the 11:00-12:00 window.

  * User can declare window state through `WindowProcessFunction#usesWindowStates` and use window state through `WindowContext#getWindowState` .

  * All window state will eventually be cleared by framework, whether or not the user clears it manually in `onClear` .

  * Window state must not be declared with a redistribution strategy. Declaring a redistributable window state (for example, a list state built with `redistributeBy`) and accessing it through `WindowContext#getWindowState` is rejected at execution with an `UnsupportedOperationException`.

  * Window state is only available for non-merging windows. Because session windows merge, calling `WindowContext#getWindowState` from a process function running on a session window is rejected at execution with an `IllegalStateException`.


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/WindowProcessFunction.java` defining functions `WindowProcessFunction.useWindowStates`. Declares `useWindowStates`, the API specified in this section for users to register window state declarations alongside their `WindowProcessFunction`.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/WindowContext.java` defining `WindowContext` with functions `WindowContext.getWindowState`. `getWindowState` provides the window-scoped state access required by this section. (`getStartTime`/`getEndTime` go to the relevant section as lifecycle context APIs; `putRecord`/`getAllRecords` are not defined on `WindowContext`.).

3. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/WindowStateStore.java` defining `WindowStateStore` with functions `WindowStateStore.WindowStateStore`, `WindowStateStore.isStateDeclared`, `WindowStateStore.stateRedistributionModeIsNotNone`, and `WindowStateStore.getWindowState`. Implements the window state storage mechanism that scopes state to individual window instances. Manages state declaration via `usesWindowStates`, state access via namespaced keys, and automatic cleanup of window state when the window is cleared by the framework.

4. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` defining functions `DefaultOneInputWindowContext.getWindowState`. `getWindowState` integrates `WindowStateStore` with the runtime state backend for single-input windows.

5. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` defining functions `DefaultTwoInputWindowContext.getWindowState`. `getWindowState` integrates `WindowStateStore` with the runtime state backend for two-input windows.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` defining functions `InternalOneInputWindowStreamProcessFunction.usesStates`. `usesStates` propagates the user's window-state declarations from `WindowProcessFunction#useWindowStates` so the runtime can register them.

7. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` defining functions `InternalTwoInputWindowStreamProcessFunction.usesStates`. Same `usesStates` propagation for two-input window functions.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` defining functions `InternalTwoOutputWindowStreamProcessFunction.usesStates`. Same `usesStates` propagation for two-output window functions.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` defining functions `OneInputWindowProcessOperator.clearAllState`. `clearAllState` releases the window-scoped state when the window is cleared by the framework.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` defining functions `TwoInputNonBroadcastWindowProcessOperator.clearAllState`. Same window-state cleanup for two-input windows.

11. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` defining functions `TwoOutputWindowProcessOperator.clearAllState`. Same window-state cleanup for two-output windows.
### Store and access all records of a window

We provide built-in window state for each window to store the input data. Users can access this through `WindowContext#putRecord` and `WindowContext#getAllRecords`. This state will be cleared when the window is cleared.

By default, `onRecord` stores the received data in the window's built-in state by `WindowContext#putRecord` , and users can retrieve all the data within the window using `WindowContext#getAllRecords` .

Therefore, when overriding `onRecord`, users should consider whether they need to write the input data into the built-in state. A typical example is if users want to do pre-aggregation, they can declare a window reduce/aggregate state, perform aggregation in `onRecord`, update the aggregated window state, and output the final result in `onTrigger` . Therefore, unnecessary cost of caching all data are eliminated.


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/OneInputWindowContext.java` defining `OneInputWindowContext` with functions `OneInputWindowContext.putRecord` and `OneInputWindowContext.getAllRecords`. Declares `putRecord`/`getAllRecords`, the built-in record storage API specified in this section for single-input windows.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/context/TwoInputWindowContext.java` defining `TwoInputWindowContext` with functions `TwoInputWindowContext.putRecord1`, `TwoInputWindowContext.getAllRecords1`, `TwoInputWindowContext.putRecord2`, and `TwoInputWindowContext.getAllRecords2`. Declares per-input `putRecord1`/`putRecord2` and `getAllRecords1`/`getAllRecords2`, the built-in record storage API for two-input windows.

3. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/OneInputWindowStreamProcessFunction.java` defining functions `OneInputWindowStreamProcessFunction.onRecord`. The default `onRecord` implementation stores records via `windowContext.putRecord(record)`, directly implementing the built-in record-storage default specified by this section.

4. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoInputNonBroadcastWindowStreamProcessFunction.java` defining functions `TwoInputNonBroadcastWindowStreamProcessFunction.onRecord1` and `TwoInputNonBroadcastWindowStreamProcessFunction.onRecord2`. The default `onRecord1`/`onRecord2` implementations store per-input records via `windowContext.putRecord1`/`putRecord2`, implementing the same built-in behavior for two-input windows.

5. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/window/function/TwoOutputWindowStreamProcessFunction.java` defining functions `TwoOutputWindowStreamProcessFunction.onRecord`. The default `onRecord` implementation stores records via `windowContext.putRecord(record)` for two-output windows.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultOneInputWindowContext.java` defining `DefaultOneInputWindowContext` with functions `DefaultOneInputWindowContext.DefaultOneInputWindowContext`, `DefaultOneInputWindowContext.setWindow`, `DefaultOneInputWindowContext.putRecord`, and `DefaultOneInputWindowContext.getAllRecords`. Constructor/`setWindow` lifecycle methods position the context against the current window before `putRecord`/`getAllRecords` persist and retrieve records from the window-scoped state, backed by `WindowStateStore`.

7. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/context/DefaultTwoInputWindowContext.java` defining `DefaultTwoInputWindowContext` with functions `DefaultTwoInputWindowContext.DefaultTwoInputWindowContext`, `DefaultTwoInputWindowContext.setWindow`, `DefaultTwoInputWindowContext.putRecord1`, `DefaultTwoInputWindowContext.getAllRecords1`, `DefaultTwoInputWindowContext.putRecord2`, and `DefaultTwoInputWindowContext.getAllRecords2`. Same per-input record storage for two-input windows via `putRecord1`/`putRecord2` and `getAllRecords1`/`getAllRecords2`.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` defining functions `OneInputWindowProcessOperator.emitWindowContents`. `emitWindowContents` reads accumulated records from the built-in window record store and drives the `onTrigger` emission flow.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` defining functions `TwoInputNonBroadcastWindowProcessOperator.emitWindowContents`. `emitWindowContents` performs the same per-input record retrieval and emission flow for two-input windows.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` defining functions `TwoOutputWindowProcessOperator.emitWindowContents`. `emitWindowContents` performs the same record retrieval and emission for two-output windows.
## Build a ProcessFunction

After declaring the Window and defining the `WindowProcessFunction` , users have to encapsulate these two components into a `ProcessFunction` . As shown below, users can use the `BuiltinFuncs.window` method to transform the `WindowStrategy` and the `WindowProcessFunction` into a `ProcessFunction` .

```java
/** Built-in functions for all extension of datastream v2. */
@Experimental
public final class BuiltinFuncs {

    ...
    
    /**
     * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
     * operation.
     */
    public static <IN, OUT> OneInputStreamProcessFunction<IN, OUT> window(
                WindowStrategy windowStrategy,
                OneInputWindowStreamProcessFunction<IN, OUT> windowProcessFunction)
    
    /**
    * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
    * operation.
    */
    public static <IN1, IN2, OUT> TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> window(
                WindowStrategy windowStrategy,
                TwoInputNonBroadcastWindowStreamProcessFunction<IN1, IN2, OUT> windowProcessFunction)

  /**
    * Wrap the WindowStrategy and WindowProcessFunction within a ProcessFunction to perform the window
    * operation.
    */
    public static <IN, OUT1, OUT2> TwoOutputStreamProcessFunction<IN, OUT1, OUT2> window(
                WindowStrategy windowStrategy,
                TwoOutputWindowStreamProcessFunction<IN, OUT1, OUT2> windowProcessFunction)

}
```

Users can integrate the encapsulated `ProcessFunction` into the data processing stream using the `DataStream#process` or `DataStream#connectAndProcess` methods.


### Implementation Guidance

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/builtin/BuiltinFuncs.java`, update `BuiltinFuncs.window`. Adds the `window` factory methods that transform a `WindowStrategy` and `WindowProcessFunction` into a `ProcessFunction`, exactly as specified in the FLIP. Provides overloads for one-input, two-input, and two-output variants.

2. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/builtin/BuiltinWindowFuncs.java` defining `BuiltinWindowFuncs` with functions `BuiltinWindowFuncs.window`. Backend implementation of `BuiltinFuncs.window` that constructs the appropriate internal window stream process functions and wires them with the provided window strategy.

3. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/GlobalStreamImpl.java`, update `GlobalStreamImpl.process` and `GlobalStreamImpl.connectAndProcess`. Extends the GlobalStream implementation to detect window-based process functions from `BuiltinFuncs.window` and route them to the appropriate window process operators instead of regular process operators.

4. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/KeyedPartitionStreamImpl.java`, update `KeyedPartitionStreamImpl.process` and `KeyedPartitionStreamImpl.connectAndProcess`. Extends the KeyedPartitionStream implementation with window support, detecting window process functions and creating window process operators for `process` and `connectAndProcess` calls.

5. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/stream/NonKeyedPartitionStreamImpl.java`, update `NonKeyedPartitionStreamImpl.process` and `NonKeyedPartitionStreamImpl.connectAndProcess`. Extends the NonKeyedPartitionStream implementation with window support for global windows (time/session windows are excluded per the FLIP specification).

6. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/utils/StreamUtils.java`, update `StreamUtils.getOutputTypeForOneInputProcessFunction`, `StreamUtils.getOutputTypeForTwoInputNonBroadcastProcessFunction`, `StreamUtils.getOutputTypesForTwoOutputProcessFunction`, `StreamUtils.getTwoInputTransformation`, `StreamUtils.transformOneInputWindow`, `StreamUtils.transformTwoInputNonBroadcastWindow`, and `StreamUtils.transformTwoOutputWindow`. Adds utility methods for creating window process operators, resolving window strategies, and constructing the stream transformations needed to integrate window operators into the DataStream pipeline.

7. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalOneInputWindowStreamProcessFunction.java` defining `InternalOneInputWindowStreamProcessFunction` with functions `InternalOneInputWindowStreamProcessFunction.InternalOneInputWindowStreamProcessFunction`, `InternalOneInputWindowStreamProcessFunction.getAssigner`, `InternalOneInputWindowStreamProcessFunction.getTrigger`, `InternalOneInputWindowStreamProcessFunction.getAllowedLateness`, `InternalOneInputWindowStreamProcessFunction.getWindowStrategy`, and `InternalOneInputWindowStreamProcessFunction.getWindowProcessFunction`. Constructor and assigner/trigger/strategy/process-function accessors that `BuiltinFuncs.window` uses to wrap a `WindowStrategy` and user `WindowProcessFunction` into the returned `ProcessFunction`.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoInputWindowStreamProcessFunction.java` defining `InternalTwoInputWindowStreamProcessFunction` with functions `InternalTwoInputWindowStreamProcessFunction.InternalTwoInputWindowStreamProcessFunction`, `InternalTwoInputWindowStreamProcessFunction.getAssigner`, `InternalTwoInputWindowStreamProcessFunction.getTrigger`, `InternalTwoInputWindowStreamProcessFunction.getAllowedLateness`, `InternalTwoInputWindowStreamProcessFunction.getWindowStrategy`, and `InternalTwoInputWindowStreamProcessFunction.getWindowProcessFunction`. Same wrapper-construction accessors for two-input window functions.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/function/InternalTwoOutputWindowStreamProcessFunction.java` defining `InternalTwoOutputWindowStreamProcessFunction` with functions `InternalTwoOutputWindowStreamProcessFunction.InternalTwoOutputWindowStreamProcessFunction`, `InternalTwoOutputWindowStreamProcessFunction.getAssigner`, `InternalTwoOutputWindowStreamProcessFunction.getTrigger`, `InternalTwoOutputWindowStreamProcessFunction.getAllowedLateness`, `InternalTwoOutputWindowStreamProcessFunction.getWindowStrategy`, and `InternalTwoOutputWindowStreamProcessFunction.getWindowProcessFunction`. Same wrapper-construction accessors for two-output window functions.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/OneInputWindowProcessOperator.java` defining functions `OneInputWindowProcessOperator.OneInputWindowProcessOperator`. Constructor that the stream implementations instantiate to integrate the window strategy/function into the runtime operator returned as a `ProcessFunction`.

11. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoInputNonBroadcastWindowProcessOperator.java` defining functions `TwoInputNonBroadcastWindowProcessOperator.TwoInputNonBroadcastWindowProcessOperator`. Same construction integration for two-input non-broadcast windows.

12. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/window/operators/TwoOutputWindowProcessOperator.java` defining functions `TwoOutputWindowProcessOperator.TwoOutputWindowProcessOperator`. Same construction integration for two-output windows.
# Compatibility, Deprecation, and Migration Plan

  1. The contents described in this FLIP is just provide an new extension for DataStream V2, no compatibility issues will be introduced.
  2. The proposed public interfaces in this FLIP will be annotated by @Experimental first, and should be changed to @PublicEvolving/@Public along with other Datastream V2 APIs.

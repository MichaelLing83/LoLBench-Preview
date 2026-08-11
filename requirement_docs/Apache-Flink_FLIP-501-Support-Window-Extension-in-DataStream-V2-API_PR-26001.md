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

    * NonKeyedStream is not supported in this FLIP, because the underlying implementation of the window extension relies on states, which is complicated on NonKeyedStream when it comes to job rescaling and state redistribution.

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
public interface TwoInputWindowStreamProcessFunction<IN1, IN2, OUT> extends WindowProcessFunction {

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

### Store and access all records of a window

We provide built-in window state for each window to store the input data. Users can access this through `WindowContext#putRecord` and `WindowContext#getAllRecords`. This state will be cleared when the window is cleared.

By default, `onRecord` stores the received data in the window's built-in state by `WindowContext#putRecord` , and users can retrieve all the data within the window using `WindowContext#getAllRecords` .

Therefore, when overriding `onRecord`, users should consider whether they need to write the input data into the built-in state. A typical example is if users want to do pre-aggregation, they can declare a window reduce/aggregate state, perform aggregation in `onRecord`, update the aggregated window state, and output the final result in `onTrigger` . Therefore, unnecessary cost of caching all data are eliminated.

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
                TwoInputWindowStreamProcessFunction<IN1, IN2, OUT> windowProcessFunction)

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

# Compatibility, Deprecation, and Migration Plan

  1. The contents described in this FLIP is just provide an new extension for DataStream V2, no compatibility issues will be introduced.
  2. The proposed public interfaces in this FLIP will be annotated by @Experimental first, and should be changed to @PublicEvolving/@Public along with other Datastream V2 APIs.

# Test Plan

 _UT & IT_

> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# FLIP-499: Support Event Time by Generalized Watermark in DataStream V2

# Background

Event time is a fundamental feature of Flink that has been widely adopted. For instance, the Window operator can determine whether to trigger a window based on event time, and users can register timer using the event time.

FLIP-467 introduces the Generalized Watermark in DataStream V2, enabling users to define specific events that can be emitted from a source or other operators, propagate along the streams, received by downstream operators, and aligned during propagation. Within this framework, the traditional (event-time) Watermark can be viewed as a special instance of the Generalized Watermark already provided by Flink.

To make it easy for users to use event time in DataStream V2, this FLIP will implement event time extension in DataStream V2 based on Generalized Watermark.

# Example

Before going into the details, let's take a look at an example to understand how event time is used in DataStream V2 job.

```java
public enum NewsEventType {
    RELEASE,
    CLICK
}

public static class NewsEvent {
    private NewsEventType type;
    private long newsId;
    private long timestamp;
}

public static class NewsClickNumber {
    private long newsId;
    private long timeAfterRelease;
    private long clickNumber;
}

private static final Duration[] TIMES_AFTER_NEWS_RELEASE =
       new Duration[] {
           Duration.ofMinutes(1),
           Duration.ofMinutes(5),
           Duration.ofMinutes(10),
           Duration.ofMinutes(30),
           Duration.ofHours(1)
       };

public static void main(String[] args) throws Exception {
    ExecutionEnvironment env = ExecutionEnvironment.getInstance();

    NonKeyedPartitionStream<NewsEvent> source = createSource(env);

    NonKeyedPartitionStream<NewsClickNumber> clickNumberStream =
          source.process(
                EventTimeExtension.newWatermarkGeneratorBuilder(
                        NewsEvent::getTimestamp)
                    .periodicWatermark(Duration.ofMillis(200))
                    .withIdleness(Duration.ofSeconds(30))
                    .withMaxOutOfOrderTime(Duration.ofSeconds(10))
                    .buildAsProcessFunction()
          )
          .keyBy(NewsEvent::getNewsId)
          .process(
                  EventTimeExtension.wrapProcessFunction(
                          new CountNewsClickNumberProcessFunction())
          );

    clickNumberStream.toSink(new WrappedSink<>(new PrintSink<>()));

    env.execute("StatisticNewsClickNumberExample");
}
```

To achieve the objectives outlined in the example, the user must complete the following tasks:

1. Generate and propagate event times in the stream 

To ensure awareness of the event time in the stream (for instance, the`CountNewsClickNumberProcessFunction` needs to determine if the current event time has reached one minute after the news release), we need to generate and propagate event times. 

In the example, we use the `WatermarkGenerator` to generate event time watermarks based on the timestamp field of the `NewsEvent` every 200 milliseconds. We have configured an idle timeout of 30 seconds, allowing for a tolerance of up to 10 seconds for event time disorder. 

It is important to note that the `WatermarkGenerator` will ultimately generate a `ProcessFunction`, which is responsible for extracting event times, generating event time watermarks, and forwarding input records. 

```java
NonKeyedPartitionStream<NewsClickNumber> clickNumberStream =
      // extract event time and generate the event time watermark
      source.process(
            // the timestamp field of the input is considered to be the
            // event time
            EventTimeExtension.newWatermarkGeneratorBuilder(
                    NewsEvent::getTimestamp)
                // generate event time watermarks every 200ms
                .periodicWatermark(Duration.ofMillis(200))
                // if the input is idle for more than 30 seconds, it
                // is ignored during the event time watermark
                // combination process
                .withIdleness(Duration.ofSeconds(30))
                // set the maximum out-of-order time of the event to
                // 30 seconds, meaning that if an event is received
                // at 12:00:00, then no further events should be
                // received earlier than 11:59:30
                .withMaxOutOfOrderTime(Duration.ofSeconds(10))
                // build the event time watermark generator as
                // ProcessFunction
                .buildAsProcessFunction()
      )
      // key by the news id
      .keyBy(NewsEvent::getNewsId)
      // count the click number of each news
      .process(
              EventTimeExtension.wrapProcessFunction(
                      new CountNewsClickNumberProcessFunction())
      );
```

2\. Let custom process function implement `OneInputEventTimeStreamProcessFunction` interface

To utilize event time within custom process function—such as registering event timers—it is necessary to implement the `OneInputEventTimeStreamProcessFunction` interface in custom process function. This will enable access to related components, including an instance of the `EventTimeManager`. 

It's important to note that `OneInputEventTimeStreamProcessFunction` is a kind of `OneInputStreamProcessFunction`, designed to provide additional components related to event time extension.

```java
public static class CountNewsClickNumberProcessFunction
        implements OneInputEventTimeStreamProcessFunction<NewsEvent, NewsClickNumber> {

    private EventTimeManager eventTimeManager;

    // news id to release time
    private final Map<Long, Long> releaseTimeOfNews = new HashMap<>();

    // news id to click time list
    private final Map<Long, List<Long>> clickTimeListOfNews = new HashMap<>();

    @Override
    public void initEventTimeStreamProcessFunction(EventTimeManager eventTimeManager) {
        this.eventTimeManager = eventTimeManager;
    }
```

3\. Register event timer and write timer callback in custom process function

In this example, we aim to count the number of clicks at intervals of 1 minute, 5 minutes, 10 minutes, and 1 hour following the release of the news. To achieve this, when a news release event occurs, we will set event timers using the `EventTimeManager` instance for the following times: news release time + 1 minute, news release time + 5 minutes, news release time + 10 minutes, news release time + 30 minutes, and news release time + 1 hour. 

```java
    @Override
    public void processRecord(
            NewsEvent record, Collector<NewsClickNumber> output, PartitionedContext ctx)
            throws Exception {
        if (record.getType() == NewsEventType.RELEASE) {
            // for the news release event, record the release time and register timers
            long releaseTime = record.getTimestamp();
            releaseTimeOfNews.put(record.getNewsId(), releaseTime);
            for (Duration targetTime : TIMES_AFTER_NEWS_RELEASE) {
                eventTimeManager.registerTimer(releaseTime + targetTime.toMillis());
            }
        } else {
            // for the news click event, record the click time
            clickTimeListOfNews
                    .computeIfAbsent(record.getNewsId(), k -> new ArrayList<>())
                    .add(record.getTimestamp());
        }
    }
```

After registering the event timers, we need to implement the timer callback function, `onEventTimer`. In this example, the `onEventTimer` function will be used to calculate the number of clicks for the news at each timer's trigger moment.

```java
    @Override
    public void onEventTimer(
            long timestamp, Collector<NewsClickNumber> output, PartitionedContext ctx) {
        // get the news that the current event timer belongs to
        long newsId = ctx.getStateManager().getCurrentKey();

        // calculate the difference between the current time and the news release time
        Duration diffTime = Duration.ofMillis(timestamp - releaseTimeOfNews.get(newsId));

        // calculate the number of clicks on the news at the current time.
        List<Long> clickTimeList = clickTimeListOfNews.get(newsId);
        long clickCount = 0;
        for (Long clickTime : clickTimeList) {
            if (clickTime <= timestamp) {
                clickCount++;
            }
        }

        // send the result to output1
        output.collect(new NewsClickNumber(newsId, diffTime.toMillis(), clickCount));
    }
}
```

4\. Wrap the custom process function by `EventTimeExtension`

In addition, we need to wrap the custom process function via `EventTimeExtension.wrapProcessFunction`, which will provide our custom process function with an `EventTimeManager` instance, declare the state required by timers, etc.

```java
/**
 * The entry point for the Event Time extension, which provides the following functionality:
 *
 * <ul>
 *   <li>defines the event time watermark.
 *   <li>provides the {@link WatermarkGeneratorBuilder} to facilitate the generation of
 *       event time watermarks.
 *   <li>provides a tool method to encapsulate a user-defined {@link EventTimeProcessFunction} to
 *       provide the relevant components of the EventTime Extension.
 * </ul>
 */
@Experimental
public class EventTimeExtension {
  
    ...

    /**
     * Wrap the user-defined {@link EventTimeProcessFunction}, which will provide related components
     * such as {@link EventTimeManager} and declare the necessary built-in state required for the
     * Timer, etc.
     */
    public static <IN, OUT> OneInputStreamProcessFunction<IN, OUT> wrapProcessFunction(
            OneInputEventTimeStreamProcessFunction<IN, OUT> processFunction) {
      ...
    }
}
```

# Proposed Changes

To utilize Generalized Watermark for supporting event time extension, we first define the associated watermarks. Then it is important to be able to support the creation and processing of watermarks.

Let's follow the steps to implement event time extension.

## Step 1 Watermarks Definition

### Event Time Watermark Definition

Before declaring the watermark, let's first define the `EventTimeWatermark`.

In this FLIP, the`EventTimeWatermark` represents a specific timestamp. Once a process function receives the `EventTimeWatermark`, it will no longer receive events with a timestamp earlier than that watermark.

The `EventTimeWatermark` signifies the passing of the time, and since time is represented as a numeric value, the`EventTimeWatermark` is of type long.

For a `ProcessFunction` with multiple input channels, it receives `EventTimeWatermark`s from all of these channels. The `ProcessFunction` should use the minimum of these `EventTimeWatermark`s as its own event time. Otherwise, it is possible for the event time of some inputs to be earlier than the `ProcessFunction`'s own event time. This could lead to the `ProcessFunction` receiving data with an event time earlier than its own, which contradicts the definition of the `EventTimeWatermark`. Therefore, the `EventTimeWatermark` should be combined using the `MIN` function.

Thus, we can define the declaration of the`EventTimeWatermark` as follows:

```java
public static final LongWatermarkDeclaration EVENT_TIME_WATERMARK_DECLARATION =
            WatermarkDeclarations.newBuilder("BUILTIN_API_EVENT_TIME")
                    .typeLong()
                    .combineFunctionMin()
                    .build();
```


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` defining `EventTimeExtension` with functions `EventTimeExtension.isEventTimeWatermark`. Declares the `EVENT_TIME_WATERMARK_DECLARATION` (long-typed, MIN-combined) public constant that matches the requirement's `EventTimeWatermark` definition, and exposes the `isEventTimeWatermark` predicate so the framework and user code can recognize event-time watermarks.

2. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java` defining `EventTimeWatermarkCombiner` and `WrappedDataOutput` with functions `EventTimeWatermarkCombiner.EventTimeWatermarkCombiner`, `EventTimeWatermarkCombiner.combineWatermark`, `WrappedDataOutput.WrappedDataOutput`, `WrappedDataOutput.setWatermarkEmitter`, `WrappedDataOutput.emitRecord`, `WrappedDataOutput.emitWatermark`, `WrappedDataOutput.emitLatencyMarker`, and `WrappedDataOutput.emitRecordAttributes`. Implements the `EventTimeWatermark` combiner — `combineWatermark` uses the `MIN` function to combine event-time watermarks from multiple input channels as specified in this section. `WrappedDataOutput.WrappedDataOutput`, `setWatermarkEmitter`, `emitRecord`, `emitWatermark`, `emitLatencyMarker`, and `emitRecordAttributes` are the wrapping data-output methods used by the combiner to forward records/watermarks downstream.

3. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java` defining `EventTimeWatermarkHandler`, `EventTimeUpdateStatus`, and `EventTimeWithIdleStatus` with functions `EventTimeWatermarkHandler.EventTimeWatermarkHandler`, `EventTimeWatermarkHandler.processEventTime`, `EventTimeWatermarkHandler.tryAdvanceEventTimeAndEmitWatermark`, `EventTimeWatermarkHandler.getCurrentEventTime`, `EventTimeWatermarkHandler.getLastEmitWatermark`, `EventTimeWatermarkHandler.processWatermark`, `EventTimeUpdateStatus.EventTimeUpdateStatus`, `EventTimeUpdateStatus.isEventTimeUpdated`, `EventTimeUpdateStatus.getNewEventTime`, `EventTimeUpdateStatus.ofUpdatedWatermark`, `EventTimeWithIdleStatus.getEventTime`, and `EventTimeWithIdleStatus.setEventTime`. Implements the event-time watermark side of the handler — tracks per-channel `EventTimeWithIdleStatus.eventTime`, advances the MIN across channels, and emits new event-time watermarks downstream via `processWatermark`.
### Idle Status Watermark Definition

There are situations where some inputs may have no data; for instance, a Kafka partition may be empty due to data skew. If this situation is not handled, the event time of the `ProcessFunction` processing the inputs with no data will cease to update, preventing the job's event time from advancing.

To address this situation, we plan to implement an `IdleStatusWatermark` in DataStream V2 through `Generalized Watermark`. The `IdleStatusWatermark` indicates that a particular input is in an idle state. When a `ProcessFunction` receives an `IdleStatusWatermark` from an input, it should ignore that input when combining `EventTimeWatermark`s.

Since `IdleStatusWatermark` is designed to indicate whether a specific input is idle, it is represented as a boolean type. 

For `ProcessFunction` with input multiple input channels, a `ProcessFunction` is considered idle only if all input channels are idle; therefore, its combination function uses a logical `AND` operation.

Thus, we can define the declaration of the`IdleStatusWatermark` as follows:

```java
public static final BoolWatermarkDeclaration IDLE_STATUS_WATERMARK_DECLARATION =
        WatermarkDeclarations.newBuilder("BUILTIN_API_EVENT_TIME_IDLE")
                .typeBool()
                .combineFunctionAND()
                .build();
```


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` defining functions `EventTimeExtension.isIdleStatusWatermark`. Declares the `IDLE_STATUS_WATERMARK_DECLARATION` (boolean-typed, AND-combined) public constant matching the requirement's `IdleStatusWatermark` definition, and exposes the `isIdleStatusWatermark` predicate for downstream recognition.

2. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkCombiner.java` defining functions `WrappedDataOutput.emitWatermarkStatus`. `WrappedDataOutput.emitWatermarkStatus` propagates the active/idle status downstream, supporting the IdleStatusWatermark mechanism where idle inputs are excluded from MIN combination.

3. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/extension/eventtime/EventTimeWatermarkHandler.java` defining functions `EventTimeWatermarkHandler.processEventTimeIdleStatus`, `EventTimeWatermarkHandler.tryEmitEventTimeIdleStatus`, `EventTimeWatermarkHandler.isAllInputIdle`, `EventTimeWithIdleStatus.isIdle`, and `EventTimeWithIdleStatus.setIdleStatus`. Implements the idle-status side of the handler — `processEventTimeIdleStatus`, `tryEmitEventTimeIdleStatus`, `isAllInputIdle`, and the `EventTimeWithIdleStatus.isIdle/setIdleStatus` accessors apply the AND combination across inputs and emit the idle-status watermark when all channels are idle.
## Step 2 Generate Watermarks

To generate and emit event time related watermarks, users can utilize the `WatermarkGeneratorBuilder` we provide, or they can implement a custom `ProcessFunction`. Both approaches will be discussed below.

### Generate watermarks by provided WatermarkGeneratorBuilder

To facilitate the generation and emission of `EventTimeWatermark`s for users, we provide the `WatermarkGeneratorBuilder`. 

In the builder, the user needs to tell us how to get the event time from the record, we denote this behaviour as `EventTimeExtractor`.

```java
/** A user function designed to extract event time from an event. */
@Experimental
public interface EventTimeExtractor<T> extends Serializable {

    /** Extract the event time from the event, with the result provided in milliseconds. */
    long extractTimestamp(T event);
}
```

Moreover, we also support three extensions related to watermark creation on builder.

  1. Input Idleness

     1. The builder allows user to set idle status for inputs. If an input has not sent data for a long time, an `IdleStatusWatermark` is generated and sent downstream.

     2. If it is not set, then no `IdleStatusWatermark` will be generated and sent.

  2. Out-of-order time

     1. To accommodate the disorder of input records, user can set a maximum out-of-order time for the `EventTimeWatermark`.

     2. The default value of maximum out-of-order time is 0, which means that the `EventTimeWatermark` will be generated directly from the extracted event time.

  3. Determine when to generate event time watermarks

     1. We support three scenarios regarding the emission of `EventTimeWatermark`s

        1. No `EventTimeWatermark`s are generated and emitted.

        2. `EventTimeWatermark`s are generated and emitted periodically.

        3. `EventTimeWatermark`s are generated and emitted for each event.

     2. By default, we will use scenario 2: periodically generating and emitting `EventTimeWatermark`s, and the periodicity interval is the value of configuration "pipeline.auto-watermark-interval".

Thus, we can give the definition of `WatermarkGeneratorBuilder` as follows.

(Note: For simplicity, the code below only includes the method signatures without the implementation details.)

```java
/** A utility class for constructing a processing function that extracts event time
 * and generates event time watermarks. */
public class WatermarkGeneratorBuilder<T> {

    // =========  how to extract event times from events =========
  
    public WatermarkGeneratorBuilder(EventTimeExtractor<T> eventTimeExtractor)

    // =========  generate the event time watermark with what value =========
  
    public WatermarkGeneratorBuilder<T> withIdleness(Duration idleTimeout)
  
    public WatermarkGeneratorBuilder<T> withMaxOutOfOrderTime(Duration maxOutOfOrderTime)
  
    // =========  when to generate event time watermark =========
  
    public WatermarkGeneratorBuilder<T> noWatermark()

    public WatermarkGeneratorBuilder<T> periodicWatermark()

    public WatermarkGeneratorBuilder<T> periodicWatermark(Duration periodicInterval)
  
    public WatermarkGeneratorBuilder<T> perEventWatermark()

    // =========  build the watermark generator as process function =========
    public OneInputStreamProcessFunction<T, T> buildAsProcessFunction()
}
```

Moreover, the `WatermarkGeneratorBuilder` can create a `ProcessFunction` that allows users to extract the event time from each event and generate the corresponding `EventTimeWatermark`.


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` defining functions `EventTimeExtension.newWatermarkGeneratorBuilder` and `EventTimeExtension.getEventTimeExtensionImplClass`. `newWatermarkGeneratorBuilder` provides the public entry point that returns an `EventTimeWatermarkGeneratorBuilder`, the the relevant section builder API; `getEventTimeExtensionImplClass` resolves the impl class used to construct the builder's ProcessFunction.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeExtractor.java` defining `EventTimeExtractor` with functions `EventTimeExtractor.extractTimestamp`. Implements the `EventTimeExtractor` functional interface that allows users to define how to extract event time from records, as specified in the requirement.

3. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkGeneratorBuilder.java` defining `EventTimeWatermarkGeneratorBuilder` with functions `EventTimeWatermarkGeneratorBuilder.EventTimeWatermarkGeneratorBuilder`, `EventTimeWatermarkGeneratorBuilder.withIdleness`, `EventTimeWatermarkGeneratorBuilder.withMaxOutOfOrderTime`, `EventTimeWatermarkGeneratorBuilder.noWatermark`, `EventTimeWatermarkGeneratorBuilder.periodicWatermark`, `EventTimeWatermarkGeneratorBuilder.perEventWatermark`, `EventTimeWatermarkGeneratorBuilder.buildAsProcessFunction`, and `EventTimeWatermarkGeneratorBuilder.getEventTimeExtensionImplClass`. Implements the `WatermarkGeneratorBuilder` with methods for configuring input idleness, out-of-order time tolerance, and watermark emission strategy (none, periodic, per-event), matching the three extensions described in the requirement.

4. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/strategy/EventTimeWatermarkStrategy.java` defining `EventTimeWatermarkStrategy` and `EventTimeWatermarkGenerateMode` with functions `EventTimeWatermarkStrategy.EventTimeWatermarkStrategy`, `EventTimeWatermarkStrategy.getEventTimeExtractor`, `EventTimeWatermarkStrategy.getGenerateMode`, `EventTimeWatermarkStrategy.getPeriodicWatermarkInterval`, `EventTimeWatermarkStrategy.getIdleTimeout`, and `EventTimeWatermarkStrategy.getMaxOutOfOrderTime`. Implements the watermark generation strategy that encapsulates the configuration from the builder, supporting the three emission scenarios (none, periodic, per-event) as specified.

5. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` defining functions `EventTimeExtensionImpl.buildAsProcessFunction`. `buildAsProcessFunction` instantiates the `ExtractEventTimeProcessFunction` from the builder's strategy, completing the the relevant section pipeline from `newWatermarkGeneratorBuilder` to a runtime ProcessFunction.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/ExtractEventTimeProcessFunction.java` defining `ExtractEventTimeProcessFunction` with functions `ExtractEventTimeProcessFunction.ExtractEventTimeProcessFunction`, `ExtractEventTimeProcessFunction.initEventTimeExtension`, `ExtractEventTimeProcessFunction.declareWatermarks`, `ExtractEventTimeProcessFunction.processRecord`, `ExtractEventTimeProcessFunction.onProcessingTime`, and `ExtractEventTimeProcessFunction.tryEmitEventTimeWatermark`. Implements the ProcessFunction created by the builder that extracts event time from each event using the `EventTimeExtractor` and generates the corresponding `EventTimeWatermark`, as described in the requirement.

7. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`, apply the required changes. The combined initialization is described under the relevant section.
### Generate watermarks by user-defined ProcessFunction

Users can create and send event-time related watermarks by customizing the `ProcessFunction`. To do this, they need to follow these steps:

  1. Declare the `EventTimeWatermarkDeclaration` in the custom `ProcessFunction`, and the `IdleStatusWatermarkDeclaration` if support for input idle is required.

  2. Create the `EventTimeWatermark` using the `EventTimeWatermarkDeclaration`.

  3. (optional) Create the `IdleStatusWatermark` using the `IdleStatusWatermarkDeclaration`.

  4. Send the watermarks through the `WatermarkManager`.

The following shows an example of this approach.

```java
public static class CustomProcessFunction
        implements OneInputStreamProcessFunction<Integer, Integer> {

    @Override
    public Collection<? extends WatermarkDeclaration> watermarkDeclarations() {
        return Set.of(
                  EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION, 
                  EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
               );
    }

    @Override
    public void processRecord(Integer record, Collector<Integer> output, PartitionedContext ctx)
            throws Exception {
        // do something as needed
        
        long eventTime = ...  // get event time from record
        // generate event time watermark and send to downstrea
        LongWatermark eventTimeWatermark = EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION.newWatermark(eventTime);
        ctx.getNonPartitionedContext()
                .getWatermarkManager()
                .emitWatermark(eventTimeWatermark);
    }
}
```

## Step 3 Handle Watermarks

To process the event-time related watermarks, user can utilize our provided `EventTimeProcessFunction` or implement their own custom process function and process it.

At the operator level, the implementation provides an internal `EventTimeWatermarkHandler` (constructed with the number of inputs, the operator output, and the time-service manager) that combines the `EventTimeWatermark`s received across its one or two inputs, advances event time, and emits the resulting event time watermark and idle status to downstream operators.

It is important to note that the first method allows for registration and deletion of event timers, while the second method requires the user to implement the event timer themselves via processing timer, etc.

Each approach is described in detail below.

### Handle watermarks by provided EventTimeProcessFunction

Before introducing the `EventTimeProcessFunction`, let's first introduce the `EventTimeManager`. This is a key component that allows users to leverage event time within the `EventTimeProcessFunction`. With the `EventTimeManager`, users can access the current event time and create or delete event timers.

```java
/**
 * This utility class allows users to register and delete event timers, as well as retrieve event
 * times. Note that it is only used in the KeyedProcessFunction.
 */
@Experimental
public interface EventTimeManager {
    /**
     * Register an event timer for this process function. The {@code onEventTimer} method will be 
     * invoked when the event time is reached.
     *
     * @param timestamp to trigger timer callback.
     */
    void registerTimer(long timestamp);

    /**
     * Deletes the event-time timer with the given trigger timestamp. This method has only an effect
     * if such a timer was previously registered and did not already expire.
     *
     * @param timestamp indicates the timestamp of the timer to delete.
     */
    void deleteTimer(long timestamp);

    /**
     * Get the current event time.
     *
     * @return current event time.
     */
    long currentTime();
}
```

We define the `EventTimeProcessFunction` interface to signify that the user intends to utilize event time in the `ProcessFunction`. This includes the ability to be aware of the advance of event time and to register event timers.

```java
/**
 * The base interface for event time process functions, indicating that the process function will
 * use event time extensions, such as registering event timers and handle event time watermarks.
 * Note that user-defined process functions should implement this sub-interface rather than this
 * interface.
 */
@Experimental
public interface EventTimeProcessFunction extends ProcessFunction {
    void initEventTimeProcessFunction(EventTimeManager eventTimeManager);
}
```

It is important to note that the `EventTimeProcessFunction` is a specialized type of `ProcessFunction`. For each subclass of `ProcessFunction`, we provide corresponding subclasses that support event time extension, e.g. `OneInputStreamProcessFunction` corresponds to `OneInputEventTimeStreamProcessFunction`. 

This means that users creating custom process functions should implement the correspoding `EventTimeProcessFunction` interface if they wish to use event time extension. For example, the `CountNewsClickNumberProcessFunction` in the example implements `OneInputEventTimeStreamProcessFunction` rather than `OneInputStreamProcessFunction`.

```java
/** A {@code EventTimeProcessFunction} interface for {@link OneInputStreamProcessFunction}. */
@Experimental
public interface OneInputEventTimeStreamProcessFunction<IN, OUT>
        extends EventTimeProcessFunction, OneInputStreamProcessFunction<IN, OUT> {

    default void onEventTimeWatermark(
            long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
            throws Exception {}

    default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
}
```

```java
/**
 * A {@code EventTimeProcessFunction} interface for {@link TwoInputBroadcastStreamProcessFunction}.
 */
@Experimental
public interface TwoInputBroadcastEventTimeStreamProcessFunction<IN1, IN2, OUT>
        extends EventTimeProcessFunction,
                TwoInputBroadcastStreamProcessFunction<IN1, IN2, OUT> {

    default void onEventTimeWatermark(
            long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
            throws Exception {}

    default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
}
```

```java
/**
 * A {@code EventTimeProcessFunction} interface for {@link
 * TwoInputNonBroadcastStreamProcessFunction}.
 */
@Experimental
public interface TwoInputNonBroadcastEventTimeStreamProcessFunction<IN1, IN2, OUT>
        extends EventTimeProcessFunction,
                TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> {

    default void onEventTimeWatermark(
            long watermarkTimestamp, Collector<OUT> output, NonPartitionedContext<OUT> ctx)
            throws Exception {}

    default void onEventTimer(long timestamp, Collector<OUT> output, PartitionedContext ctx) {}
}
```

```java
/** A {@code EventTimeProcessFunction} interface for {@link TwoOutputStreamProcessFunction}. */
@Experimental
public interface TwoOutputEventTimeStreamProcessFunction<IN, OUT1, OUT2>
        extends EventTimeProcessFunction, TwoOutputStreamProcessFunction<IN, OUT1, OUT2> {

    default void onEventTimeWatermark(
            long watermarkTimestamp,
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputNonPartitionedContext<OUT1, OUT2> ctx)
            throws Exception {}

    default void onEventTimer(
            long timestamp,
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputPartitionedContext ctx) {}
}
```

Compared with `ProcessFunction`, `EventTimeProcessFunction` has three more methods.

a. `initEventTimeProcessFunction`

This method enables the `EventTimeProcessFunction` to access some event time extension related components, such as `EventTimeManager` instance.

b. `onEventTimeWatermark`

This method signifies that the `ProcessFunction` has received an `EventTimeWatermark`. It is important to note in `EventTimeProcessFunction`, the `EventTimeWatermark`s will be processed by `EventTimeProcessFunction#onEventTimeWatermark`, whereas other types of watermarks will be processed by the `ProcessFunction#onWatermark`.

c. onEventTimer

This callback method is triggered by the event timer. Within this method, users can access the key and event time associated with the event timer, perform necessary calculations, and output the results.

To utilize the `EventTimeProcessFunction`, users should follow these two steps:

  1. Implement a custom process function by implement one type of `EventTimeProcessFunction`.

  2. Wrap the user-defined process function using `EventTimeUtils#wrapProcessFunction`. This step will provide related components, such as instance of `EventTimeManager`, and will declare the necessary built-in state required for timers, etc.

```java
/**
 * The entry point for the Event Time extension, which provides the following functionality:
 *
 * <ul>
 *   <li>defines the event time watermark.
 *   <li>provides the {@link WatermarkGeneratorBuilder} to facilitate the generation of
 *       event time watermarks.
 *   <li>provides a tool method to encapsulate a user-defined {@link EventTimeProcessFunction} to
 *       provide the relevant components of the EventTime Extension.
 * </ul>
 */
@Experimental
public class EventTimeExtension {
  
    ...

    /**
     * Wrap the user-defined {@link EventTimeProcessFunction}, which will provide related components
     * such as {@link EventTimeManager} and declare the necessary built-in state required for the
     * Timer, etc.
     */
    public static <IN, OUT> OneInputStreamProcessFunction<IN, OUT> wrapProcessFunction(
            OneInputEventTimeStreamProcessFunction<IN, OUT> processFunction) {
      ...
    }
}
```


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java` defining functions `EventTimeExtension.wrapProcessFunction`.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/EventTimeProcessFunction.java` defining `EventTimeProcessFunction` with functions `EventTimeProcessFunction.initEventTimeProcessFunction`. Defines the base `EventTimeProcessFunction` interface with the three additional methods: `initEventTimeProcessFunction`, `onEventTimeWatermark`, and `onEventTimer`, as specified in the requirement.

3. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/OneInputEventTimeStreamProcessFunction.java` defining `OneInputEventTimeStreamProcessFunction` with functions `OneInputEventTimeStreamProcessFunction.onEventTimeWatermark` and `OneInputEventTimeStreamProcessFunction.onEventTimer`. Implements the `OneInputEventTimeStreamProcessFunction` subclass corresponding to `OneInputStreamProcessFunction`, as specified in the requirement's subclass hierarchy.

4. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputBroadcastEventTimeStreamProcessFunction.java` defining `TwoInputBroadcastEventTimeStreamProcessFunction` with functions `TwoInputBroadcastEventTimeStreamProcessFunction.onEventTimeWatermark` and `TwoInputBroadcastEventTimeStreamProcessFunction.onEventTimer`. Implements the `TwoInputBroadcastEventTimeStreamProcessFunction` subclass for broadcast two-input process functions with event time support.

5. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoInputNonBroadcastEventTimeStreamProcessFunction.java` defining `TwoInputNonBroadcastEventTimeStreamProcessFunction` with functions `TwoInputNonBroadcastEventTimeStreamProcessFunction.onEventTimeWatermark` and `TwoInputNonBroadcastEventTimeStreamProcessFunction.onEventTimer`. Implements the `TwoInputNonBroadcastEventTimeStreamProcessFunction` subclass for non-broadcast two-input process functions with event time support.

6. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/function/TwoOutputEventTimeStreamProcessFunction.java` defining `TwoOutputEventTimeStreamProcessFunction` with functions `TwoOutputEventTimeStreamProcessFunction.onEventTimeWatermark` and `TwoOutputEventTimeStreamProcessFunction.onEventTimer`. Implements the `TwoOutputEventTimeStreamProcessFunction` subclass for two-output process functions with event time support.

7. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/timer/EventTimeManager.java` defining `EventTimeManager` with functions `EventTimeManager.registerTimer`, `EventTimeManager.deleteTimer`, and `EventTimeManager.currentTime`. Implements the `EventTimeManager` interface allowing users to access current event time, register event timers, and delete event timers, as specified in the requirement.

8. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` defining `EventTimeExtensionImpl` with functions `EventTimeExtensionImpl.wrapProcessFunction`. `wrapProcessFunction` overloads construct the concrete `EventTimeWrapped*` wrappers required by the relevant section, handling state declaration and component initialization that delivers `EventTimeManager` to the user function.

9. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedOneInputStreamProcessFunction.java` defining `EventTimeWrappedOneInputStreamProcessFunction` with functions `EventTimeWrappedOneInputStreamProcessFunction.EventTimeWrappedOneInputStreamProcessFunction`, `EventTimeWrappedOneInputStreamProcessFunction.open`, `EventTimeWrappedOneInputStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedOneInputStreamProcessFunction.processRecord`, `EventTimeWrappedOneInputStreamProcessFunction.endInput`, `EventTimeWrappedOneInputStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedOneInputStreamProcessFunction.onWatermark`, `EventTimeWrappedOneInputStreamProcessFunction.onEventTime`, `EventTimeWrappedOneInputStreamProcessFunction.usesStates`, `EventTimeWrappedOneInputStreamProcessFunction.declareWatermarks`, `EventTimeWrappedOneInputStreamProcessFunction.close`, and `EventTimeWrappedOneInputStreamProcessFunction.getWrappedUserFunction`. Wraps a `OneInputEventTimeStreamProcessFunction` to provide event time components (EventTimeManager), intercept watermarks for `onEventTimeWatermark` delegation, and handle timer callbacks via `onEventTimer`.

10. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputBroadcastStreamProcessFunction.java` defining `EventTimeWrappedTwoInputBroadcastStreamProcessFunction` with functions `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.EventTimeWrappedTwoInputBroadcastStreamProcessFunction`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.open`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.processRecordFromNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.processRecordFromBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.endBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.endNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onWatermarkFromBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onWatermarkFromNonBroadcastInput`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.close`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.usesStates`, `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.declareWatermarks`, and `EventTimeWrappedTwoInputBroadcastStreamProcessFunction.getWrappedUserFunction`. Wraps a `TwoInputBroadcastEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.

11. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.java` defining `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction` with functions `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.open`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.processRecordFromFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.processRecordFromSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.endFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.endSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onWatermarkFromFirstInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onWatermarkFromSecondInput`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.close`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.usesStates`, `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.declareWatermarks`, and `EventTimeWrappedTwoInputNonBroadcastStreamProcessFunction.getWrappedUserFunction`. Wraps a `TwoInputNonBroadcastEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.

12. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/functions/EventTimeWrappedTwoOutputStreamProcessFunction.java` defining `EventTimeWrappedTwoOutputStreamProcessFunction` with functions `EventTimeWrappedTwoOutputStreamProcessFunction.EventTimeWrappedTwoOutputStreamProcessFunction`, `EventTimeWrappedTwoOutputStreamProcessFunction.open`, `EventTimeWrappedTwoOutputStreamProcessFunction.initEventTimeExtension`, `EventTimeWrappedTwoOutputStreamProcessFunction.processRecord`, `EventTimeWrappedTwoOutputStreamProcessFunction.endInput`, `EventTimeWrappedTwoOutputStreamProcessFunction.onProcessingTimer`, `EventTimeWrappedTwoOutputStreamProcessFunction.onWatermark`, `EventTimeWrappedTwoOutputStreamProcessFunction.onEventTime`, `EventTimeWrappedTwoOutputStreamProcessFunction.usesStates`, `EventTimeWrappedTwoOutputStreamProcessFunction.declareWatermarks`, `EventTimeWrappedTwoOutputStreamProcessFunction.close`, and `EventTimeWrappedTwoOutputStreamProcessFunction.getWrappedUserFunction`. Wraps a `TwoOutputEventTimeStreamProcessFunction` with event time support, intercepting watermarks and providing timer callbacks.

13. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/timer/DefaultEventTimeManager.java` defining `DefaultEventTimeManager` with functions `DefaultEventTimeManager.DefaultEventTimeManager`, `DefaultEventTimeManager.registerTimer`, `DefaultEventTimeManager.deleteTimer`, and `DefaultEventTimeManager.currentTime`. Implements the `EventTimeManager` interface, providing concrete implementations of current event time access, timer registration, and timer deletion using the underlying processing timer service.

14. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java`, update `KeyedProcessOperator.onEventTime`, `KeyedProcessOperator.getTimerService`, and `KeyedProcessOperator.getEventTimeSupplier`. `onEventTime` delegates the event-timer callback to the wrapped `EventTimeProcessFunction`, while `getTimerService` and `getEventTimeSupplier` expose the event-timer service and current-event-time supplier required by `DefaultEventTimeManager` to fulfill the relevant `EventTimeManager` contract in the keyed one-input operator.

15. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java`, update `KeyedTwoInputBroadcastProcessOperator.onEventTime`, `KeyedTwoInputBroadcastProcessOperator.getTimerService`, and `KeyedTwoInputBroadcastProcessOperator.getEventTimeSupplier`. Same the relevant section event-timer delegation and service access as `KeyedProcessOperator`, for the broadcast keyed two-input operator.

16. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java`, update `KeyedTwoInputNonBroadcastProcessOperator.onEventTime`, `KeyedTwoInputNonBroadcastProcessOperator.getTimerService`, and `KeyedTwoInputNonBroadcastProcessOperator.getEventTimeSupplier`. Same the relevant section event-timer delegation and service access as `KeyedProcessOperator`, for the non-broadcast keyed two-input operator.

17. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java`, update `KeyedTwoOutputProcessOperator.onEventTime`, `KeyedTwoOutputProcessOperator.getTimerService`, and `KeyedTwoOutputProcessOperator.getEventTimeSupplier`. Same the relevant section event-timer delegation and service access as `KeyedProcessOperator`, for the keyed two-output operator.

18. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`, update `ProcessOperator.open`, `ProcessOperator.getProcessorWithKey`, `ProcessOperator.getTimerService`, and `ProcessOperator.getEventTimeSupplier`. `open` constructs the `EventTimeWrappedOneInputStreamProcessFunction` around any user-provided `EventTimeProcessFunction` and primes the operator with an event-time-aware processor, which is the the relevant section one-input initialization path (the same function also activates the the relevant section builder's `ExtractEventTimeProcessFunction`, which is the unavoidable coarse function ownership noted under the relevant section). `getProcessorWithKey`, `getTimerService`, and `getEventTimeSupplier` expose the event-time services that the wrapped `EventTimeProcessFunction` and its `DefaultEventTimeManager` consume to read current event time and register/delete event timers per the relevant section.

19. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java`, update `TwoInputBroadcastProcessOperator.open`, `TwoInputBroadcastProcessOperator.getTimerService`, and `TwoInputBroadcastProcessOperator.getEventTimeSupplier`. `open` initializes the broadcast wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services the relevant `EventTimeManager` needs.

20. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java`, update `TwoInputNonBroadcastProcessOperator.open`, `TwoInputNonBroadcastProcessOperator.getTimerService`, and `TwoInputNonBroadcastProcessOperator.getEventTimeSupplier`. `open` initializes the non-broadcast wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services the relevant `EventTimeManager` needs.

21. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java`, update `TwoOutputProcessOperator.open`, `TwoOutputProcessOperator.getTimerService`, and `TwoOutputProcessOperator.getEventTimeSupplier`. `open` initializes the two-output wrapped event-time process function; `getTimerService` and `getEventTimeSupplier` expose the services the relevant `EventTimeManager` needs.
### Handle watermarks by user-defined ProcessFunction

Similarly, users can handle event time related watermarks by implementing `ProcessFunction` instead of `EventTimeProcessFunction`. 

In this approach, users must evaluate whether the current watermark received is an `EventTimeWatermark` or `IdleStatusWatermark` within the `ProcessFunction#onWatermark` method and execute the appropriate processing logic accordingly. An example is provided below.

```java
public static class CustomProcessFunction
        implements OneInputStreamProcessFunction<Integer, Integer> {

    @Override
    public WatermarkHandlingResult onWatermark(
            Watermark watermark,
            Collector<Integer> output,
            NonPartitionedContext<Integer> ctx) throws Exception {
        if (EventTimeExtension.isEventTimeWatermark(watermark)) {
            // do something as needed
            ...
            return WatermarkHandlingResult.PEEK;
        } else if (EventTimeExtension.isIdleStatusWatermark(watermark)) {
            // do something as needed
            ...
            return WatermarkHandlingResult.PEEK;
        } else {
            // do something as needed
            ...
        }
    }
}
```

It is important to note that when `ProcessFunction#onWatermark` handles event-time relaed watermark, it should return `WatermarkHandlingResult#PEEK`. This indicates that the Flink framework will choose the processing logic based on the watermark definition. For `EventTimeWatermark` and `IdleStatusWatermark`, the Flink framework will forward the watermark downstream.

Conversely, if `ProcessFunction#onWatermark` returns `WatermarkHandlingResult#POP`, the watermarks will not be sent downstream by the Flink framework. Users should be aware that this may result in the loss of the watermark, or they may need to send the watermark manually.


### Implementation Guidance

1. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/extension/eventtime/EventTimeExtension.java`. the relevant section is the consumer of those predicates rather than their owner.

2. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/extension/eventtime/EventTimeExtensionImpl.java` defining functions `EventTimeExtensionImpl.isEventTimeExtensionWatermark`. `isEventTimeExtensionWatermark` backs the public predicates, allowing user-defined `onWatermark` implementations to detect event-time-extension watermarks per the relevant section.

3. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`, update `ProcessOperator.processWatermarkInternal`. `processWatermarkInternal` implements the PEEK/POP watermark handling: when the user's `onWatermark` returns `PEEK`, the framework forwards event-time/idle-status watermarks downstream per the relevant section; when it returns `POP`, downstream propagation is suppressed.

4. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java`, update `TwoInputBroadcastProcessOperator.processWatermark1Internal` and `TwoInputBroadcastProcessOperator.processWatermark2Internal`. `processWatermark1Internal`/`processWatermark2Internal` apply the same PEEK/POP watermark handling for the broadcast two-input operator per the relevant section.

5. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java`, update `TwoInputNonBroadcastProcessOperator.processWatermark1Internal` and `TwoInputNonBroadcastProcessOperator.processWatermark2Internal`. `processWatermark1Internal`/`processWatermark2Internal` apply the same PEEK/POP watermark handling for the non-broadcast two-input operator per the relevant section.

6. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java`, update `TwoOutputProcessOperator.processWatermarkInternal`. `processWatermarkInternal` applies the same PEEK/POP watermark handling for the two-output operator per the relevant section.
# Compatibility, Deprecation, and Migration Plan

  1. The contents described in this FLIP is just provide an new extension for DataStream V2, no compatibility issues will be introduced.
  2. The proposed public interfaces in this FLIP will be annotated by @Experimental first, and should be changed to @PublicEvolving/@Public along with other Datastream V2 APIs.

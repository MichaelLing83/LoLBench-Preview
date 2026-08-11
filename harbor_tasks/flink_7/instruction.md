You are working in `/workspace/flink`, a source tree checked out at
the base commit for this task. Implement the requested behavior in the source
tree, then run:

```bash
lolbench-submit
```

Do not stop after editing files, running tests, or describing the solution. The
task is complete only when `lolbench-submit` has created
`/logs/artifacts/solution.patch`. If that file does not exist, continue
working and run `lolbench-submit` again.

That command writes your implementation diff to
`/logs/artifacts/solution.patch`, which is the artifact the Harbor verifier
will grade. Before running `lolbench-submit`, clean or revert any test files
you created or modified; test files must not be included in the final
`solution.patch`.

This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

Now please implement the following requirements in the source tree:

---

# FLIP-467: Introduce Generalized Watermarks

Please keep the discussion on the mailing list rather than commenting on the wiki (wiki discussions get unwieldy fast).

# Background

A Watermark is a special event that is emitted from the Source and pushes the Flink event time forward through propagation and alignment across the stream. 

Such propagation and alignment mechanisms are actually widespread: For example, the IsProcessingBacklog event proposed by FLIP-309. This inspires us to abstract a more general watermark framework that is no longer restricted to event time semantics. It represents a kind of event/signal that can be emitted from the source or other operators, propagate along the streams, received by downstream operators, and aligned during propagation. With this abstraction, the original event-time watermark can be seen as a built-in use case of it. 

# Example:

Before going into the details, let's take a look at an end-to-end example to understand how generalized watermark is used in DataStream V2 job. 

```java
public class DetectHotTopicExample {

    static final String NEWEST_TWEET_TIME_WM_ID = "newest-tweet-posting-time";

    static class ExtractTopicAndPostingTimeFunction
            implements OneInputStreamProcessFunction<Tweet, Tuple2<String, Long>> {

        // declare the watermark and it's combination strategy
        private static final WatermarkDeclaration newestTweetTimeWMD =
                WatermarkDeclarations.newBuilder(NEWEST_TWEET_TIME_WM_ID)
                        .typeLong()
                        .combineFunctionMax()
                        .build();

        private long newestPostingTime = -1L; // use variable instead of state for simplicity

        @Override
        public Collection<WatermarkDeclaration> watermarkDeclarations() {
            return Collections.singleton(newestTweetTimeWMD);
        }

        @Override
        public void processRecord(
                Tweet record,
                Collector<Tuple2<String, Long>> output,
                PartitionedContext ctx)
                throws Exception {
            String topic = record.getTopic();
            long time = record.getPostingTime();

            // extract the topic and posting time, and forward to downstream
            output.collect(Tuple2.of(topic, time));

            // if the posting time is the newest, emit a new watermark
            if (time > newestPostingTime) {
                newestPostingTime = time;
                // emite the watermark
                ctx.getNonPartitionedContext().getWatermarkManager()
                        .emitWatermark(
newestTweetTimeWMD.newWatermark(newestPostingTime));
            }
        }
    }

    static class DetectHotTopic
            implements OneInputStreamProcessFunction<Tuple2<String, Long>, Tuple2<String, Long>> {

        private static final int HOT_TOPIC_NUM_THRESHOLD = 100;
        private static final long HOT_TOPIC_TIME_THRESHOLD = 5 * 60 * 1000L;
        private Map<String, PriorityQueue<Long>> cachedTweetsByTopic =
                new HashMap<>(); // use variable instead of state for simplicity

        @Override
        public void processRecord(
                Tuple2<String, Long> record,
                org.apache.flink.datastream.api.common.Collector<Tuple2<String, Long>> output,
                PartitionedContext ctx)
                throws Exception {
            String topic = record.f0;
            Long timestamp = record.f1;

            // cache the new received tweet
            PriorityQueue<Long> cachedTweets =
                    cachedTweetsByTopic.computeIfAbsent(topic, (ignore) -> new PriorityQueue<>());
            cachedTweets.add(timestamp);

            // if the topic is hot, output
            if (cachedTweets.size() > HOT_TOPIC_NUM_THRESHOLD) {
                output.collect(
                        Tuple2.of(
                                topic,
                                cachedTweets.peek() // the time that the topic starts to be hot
                                ));
            }
        }

        @Override
        public WatermarkHandlingResult onWatermark(
                Watermark watermark, Collector<Long> output, NonPartitionedContext<Long> ctx) {
            // handle the watermark in process function
            if (watermark.getIdentifier().equals(NEWEST_TWEET_TIME_WM_ID)) {
                // remove cached tweets 5 minutes earlier than th newest
                cachedTweetsByTopic.forEach(
                        (topic, tweetsInOrder) -> {
                            while (!tweetsInOrder.isEmpty()
                                    && watermark.getValue() - tweetsInOrder.peek()
                                            > HOT_TOPIC_TIME_THRESHOLD) {
                                tweetsInOrder.poll();
                            }
                        });
            }
            return WatermarkHandlingResult.PEEK; // we don't know if any downstream PF is relying on the watermark
        }
    }

    public static void main(String[] args) throws Exception {
        ExecutionEnvironment env = ExecutionEnvironment.getInstance();

        Source<Tweet> someSource = new Source<>(); // Simplified code
        Sink<Tuple2<String, Long>> someSink = new Sink<>(); // Simplified code

        env.fromSource(someSource)
                .process(new ExtractTopicAndPostingTimeFunction())
                .keyBy(tuple -> tuple.f0) // by topic
                .process(new DetectHotTopic())
                .toSink(someSink);

        env.execute();
    }
}
```

In a nutshell, there are four steps in defining and using generalized watermark, which are:

  * Upstream Function:  

    * **Step1: Declare watermark**
      1. The `Long` type of watermark is defined corresponding to the following code snippet in the example. This watermark is then declared in the `watermarkDeclarations` method.

```java
// define watermark
private static final WatermarkDeclaration newestTweetTimeWMD = WatermarkDeclarations.newBuilder(NEWEST_TWEET_TIME_WM_ID) // ID(identifier) is always required
        .typeLong()
        ...
        .build();

// declare watermark
public Collection<WatermarkDeclaration> watermarkDeclarations() {
   return Collections.singleton(newestTweetTimeWMD);
}
```

    * **Step2: Emit watermark**
      1. Send watermark to downstream from the source or process function.
      2. Corresponding to the example above: If we find the newest twitter in the processRecord method, emit a watermark with this posting time to downstream through the `WatermarkManager`.

```java
@Override
public void processRecord(
		Tweet record,
    	    Collector<Tuple2<String, Long>> output,
            	PartitionedContext ctx) throws Exception {
 	String topic = record.getTopic();
    long time = record.getPostingTime();

    // extract the topic and posting time, and forward to downstream
    output.collect(Tuple2.of(topic, time));

    // if the posting time is the newest, emit a new watermark
    if (time > newestPostingTime) {
		newestPostingTime = time;
		// emite the watermark via WatermarkManager
		ctx.getNonPartitionedContext().getWatermarkManager().emitWatermark(
newestTweetTimeWMD.newWatermark(newestPostingTime));
     }
}
```

  * Downstream Function:

    * **Step3: Combine watermark**

      1. Combine all watermarks from multiple input channels, and then push it to process function.

      2. When we build the `WatermarkDeclaration`, we have to decide the `CombinationFunction` for it.

```java
private static final WatermarkDeclaration newestTweetTimeWMD = WatermarkDeclarations.newBuilder(NEWEST_TWEET_TIME_WM_ID)
        ...
        // define the combination function for multiple channels.
        .combineFunctionMax() // always pick the newest tweet among all parallel upstreams
        .build();
```

For downstream function, when multiple channels receive watermarks, combine all of watermarks via the Max strategy as we always pick the newest tweet among all parallel upstreams.

    * **Step4: Handle watermark**

      1. Handle watermarks in process function if any input receive a new watermark.

      2. In this example, we process the incoming watermark in the downstream function's `onWatermark `callback.

```java
// handle the watermark in process function
@Override
public WatermarkHandlingResult onWatermark(Watermark watermark, Collector<Long> output, NonPartitionedContext<Long> ctx) {
	if (watermark.getIdentifier().equals(NEWEST_TWEET_TIME_WM_ID)) {
		// remove cached tweets 5 minutes earlier than th newest
		cachedTweetsByTopic.forEach(
			(topic, tweetsInOrder) -> {
				while (!tweetsInOrder.isEmpty() && watermark.getValue() - tweetsInOrder.peek() > HOT_TOPIC_TIME_THRESHOLD) {
					tweetsInOrder.poll();
				}
			}
		);
	}
	return WatermarkHandlingResult.PEEK; // we don't know if any downstream PF is relying on the watermark
}
```

You can go back to the example and see the full picture of using generalized watermark.

# Proposed Changes

In order to implement the four steps mentioned above, we propose the following changes:

### Watermark Definition

First of all, let's define the _**watermark**_.

(Note: The _**watermark**_ in the subsequent content refers to the generalized watermark proposed in this FLIP)

```java
/* * This interface represents a watermark. It will provide a unified triggering and
 * alignment mechanism for user-defined event-like things.
 */
@Experimental
public interface Watermark extends Serializable {
    /**
     * Returns the unique identifier for this watermark.
     *
     * @return a {@code String} representing the unique identifier of the watermark
     */
    String getIdentifier();
}
```

The identifiers for watermarks are case-sensitive and must be globally unique throughout the entire job. To prevent identifier duplication, the Flink internal watermark identifiers and the identifiers developed for connectors can be prefixed with the name of their respective module or connector. For example, they could be named "INTERNAL_RUNTIME_BACKLOG" or "CONNECTOR_KAFKA_IDLE."

We currently only expose the following two types of _**Watermark**_ to users (which is enough to meet our known requirements for generalized watermark), but if we see more requirements in the future, we can consider letting users customize watermark(i.e. allow them to implement Watermark interface themselves).

```java
/**
 * The {@link LongWatermark}  represents a watermark with a long value and
 * an associated identifier.
 */
@Experimental
public class LongWatermark implements Watermark {
    private static final long serialVersionUID = 1L;
    private final long value;
    private final String identifier;

    public LongWatermark(long value, String identifier) {
        this.value = value;
        this.identifier = identifier;
    }

    public long getValue() {
        return value;
    }

    @Override
    public String getIdentifier() {
        return identifier;
    }
}
```

```java
/**
 * The {@link BoolWatermark} represents a watermark with a boolean value and an
 * associated identifier.
 */
@Experimental
public class BoolWatermark implements Watermark {
    private static final long serialVersionUID = 1L;
    private final boolean value;
    private final String identifier;

    public BoolWatermark(boolean value, String identifier) {
        this.value = value;
        this.identifier = identifier;
    }

    public boolean getValue() {
        return value;
    }

    @Override
    public String getIdentifier() {
        return identifier;
    }
}
```

Note that the new _**`Watermark`**_ is completely decoupled from any watermark/marker-specific (e.g., time-specific) semantics. 

### Declare Watermark

Before emitting _**Watermark**_ , you must declare it in advance and define the alignment and propagation semantics.

```java
/**
 * This class represents the watermark creation and handling policy defined by the user.
 */
@Experimental
public interface WatermarkDeclaration extends Serializable {
    /**
     * Returns the unique identifier for this watermark.
     *
     * @return a {@code String} representing the unique identifier of the watermark
     */
    String getIdentifier();
}
```

Since only two types of _**Watermark**_ are provided, their corresponding _**`Declaration`**_ is as follows:

Note: The definition and role of _**`WatermarkCombinationPolicy`**_ and _**`WatermarkHandlingStrategy`**_ , see later in this FLIP.

```java
/**
 * The {@link LongWatermarkDeclaration} class implements the {@link WatermarkDeclaration} interface
 * and provides additional functionality specific to long-type watermarks. It includes methods for
 * obtaining combination semantics and creating new long watermarks.
 */
@Experimental
public class LongWatermarkDeclaration implements WatermarkDeclaration {

    private final String identifier;

    private final WatermarkCombinationPolicy combinationPolicy;

    private final WatermarkHandlingStrategy defaultHandlingStrategy;

    public LongWatermarkDeclaration(
            String identifier,
            WatermarkCombinationPolicy combinationPolicy,
            WatermarkHandlingStrategy defaultHandlingStrategy) {
        this.identifier = identifier;
        this.combinationPolicy = combinationPolicy;
        this.defaultHandlingStrategy = defaultHandlingStrategy;
    }

    @Override
    public String getIdentifier() {
        return identifier;
    }

    public WatermarkCombinationPolicy getCombinationPolicy() {
        return combinationPolicy;
    }

    public WatermarkHandlingStrategy getDefaultHandlingStrategy() {
        return defaultHandlingStrategy;
    }

    /** Creates a new {@link LongWatermark} with the specified long value. */
    public LongWatermark newWatermark(long val) {
        return new LongWatermark(val, identifier);
    };
}
```

```java
/**
 * The {@link BoolWatermarkDeclaration} class implements the {@link WatermarkDeclaration} interface
 * and provides additional functionality specific to boolean-type watermarks. It includes methods for
 * obtaining combination semantics and creating new bool watermarks.
 */
@Experimental
public class BoolWatermarkDeclaration implements WatermarkDeclaration {

    private final String identifier;

    private final WatermarkCombinationPolicy combinationPolicy;

    private final WatermarkHandlingStrategy defaultHandlingStrategy;

    public BoolWatermarkDeclaration(
            String identifier,
            WatermarkCombinationPolicy combinationPolicy,
            WatermarkHandlingStrategy defaultHandlingStrategy) {
        this.identifier = identifier;
        this.combinationPolicy = combinationPolicy;
        this.defaultHandlingStrategy = defaultHandlingStrategy;
    }

    @Override
    public String getIdentifier() {
        return identifier;
    }

    public WatermarkCombinationPolicy getCombinationPolicy() {
        return combinationPolicy;
    }

    public WatermarkHandlingStrategy getDefaultHandlingStrategy() {
        return defaultHandlingStrategy;
    }

    /** Creates a new {@link BoolWatermark} with the specified boolean value. */
    public BoolWatermark newWatermark(boolean val) {
        return new BoolWatermark(val, identifier);
    }
}
```

Since only _**Process Function**_ and _**Source**_ can emit _**watermark**_ , the following methods are introduced for each of them to declare watermark.

  1. _**Watermark**_ from _**Process Function**_

```java
public interface ProcessFunction extends Function {
  
  /**
   * Explicitly declare watermarks upfront. Each specific watermark must be declared in this method
   * before it can be used.
   *
   * @return all watermark declarations used by this application.
   */
  default Collection<? extends WatermarkDeclaration> watermarkDeclarations() {
      return Collections.emptySet();
  }
}
```

  2.  _**Watermark**_ from _**Source**_

```java
public interface Source<T, SplitT extends SourceSplit, EnumChkT>
        extends SourceReaderFactory<T, SplitT> {
  /**
   * Explicitly declare watermarks upfront. Each specific watermark must be declared in this method
   * before it can be used.
   *
   * @return all watermark declarations used by this application.
   */
  default Collection<? extends WatermarkDeclaration> watermarkDeclarations() {
      return Collections.emptySet();
  }
}
```

To facilitate the creation of _**`WatermarkDeclaration`**_ , we provide the build tool:

```java
/** The Utils class is used to create {@link WatermarkDeclaration}. */
@Experimental
public class WatermarkDeclarations {

    public static WatermarkBuilder newBuilder(String identifier) {
        return new WatermarkBuilder(identifier);
    }

    /** Builder class for {@link WatermarkDeclaration}s. */
    @Experimental
    public static class WatermarkBuilder {

        protected final String identifier;

        WatermarkBuilder(String identifier) {
            this.identifier = identifier;
        }

        public LongWatermarkBuilder typeLong() {
            return new LongWatermarkBuilder(identifier);
        }

        public BoolWatermarkBuilder typeBool() {
            return new BoolWatermarkBuilder(identifier);
        }

        @Experimental
        public static class LongWatermarkBuilder {
            private final String identifier;
            private boolean combineWaitForAllChannels = false;
            // for channels
            private WatermarkCombinationFunction combinationFunction =
                    NumericWatermarkCombinationFunction.MIN;
            // for function
            private WatermarkHandlingStrategy defaultHandlingStrategy =
                    WatermarkHandlingStrategy.FORWARD;

            public LongWatermarkBuilder(String identifier) {
                this.identifier = identifier;
            }

            /** Combine and propagate the maximum watermark to downstream. */
            public LongWatermarkBuilder combineFunctionMax() {
                this.combinationFunction = NumericWatermarkCombinationFunction.MAX;
                return this;
            }

            /** Combine and propagate the minimum watermark to downstream. */
            public LongWatermarkBuilder combineFunctionMin() {
                this.combinationFunction = NumericWatermarkCombinationFunction.MIN;
                return this;
            }

            public LongWatermarkBuilder defaultHandlingStrategyForward() {
                this.defaultHandlingStrategy = WatermarkHandlingStrategy.FORWARD;
                return this;
            }

            public LongWatermarkBuilder defaultHandlingStrategyIgnore() {
                this.defaultHandlingStrategy = WatermarkHandlingStrategy.IGNORE;
                return this;
            }

            /**
             * Whether the combine process should be executed after the process function receives
             * watermarks from both upstream channels.
             */
            public LongWatermarkBuilder combineWaitForAllChannels(
                    boolean combineWaitForAllChannels) {
                this.combineWaitForAllChannels = combineWaitForAllChannels;
                return this;
            }

            public LongWatermarkDeclaration build() {
                return new LongWatermarkDeclaration(
                        identifier,
                        new WatermarkCombinationPolicy(
                                this.combinationFunction, this.combineWaitForAllChannels),
                        this.defaultHandlingStrategy);
            }
        }

        @Experimental
        public static class BoolWatermarkBuilder {
            private final String identifier;
            private boolean combineWaitForAllChannels = false;
            // for channels
            private WatermarkCombinationFunction combinationFunction =
                    BoolWatermarkCombinationFunction.AND;
            // for function
            private WatermarkHandlingStrategy defaultHandlingStrategy =
                    WatermarkHandlingStrategy.FORWARD;

            public BoolWatermarkBuilder(String identifier) {
                this.identifier = identifier;
            }

            /** Propagate the logical OR combination result of boolean watermarks downstream. */
            public BoolWatermarkBuilder combineFunctionOR() {
                this.combinationFunction = BoolWatermarkCombinationFunction.OR;
                return this;
            }

            /** Propagate the logical AND combination result of boolean watermarks downstream. */
            public BoolWatermarkBuilder combineFunctionAND() {
                this.combinationFunction = BoolWatermarkCombinationFunction.AND;
                return this;
            }

            public BoolWatermarkBuilder defaultHandlingStrategyForward() {
                this.defaultHandlingStrategy = WatermarkHandlingStrategy.FORWARD;
                return this;
            }

            public BoolWatermarkBuilder defaultHandlingStrategyIgnore() {
                this.defaultHandlingStrategy = WatermarkHandlingStrategy.IGNORE;
                return this;
            }

            /**
             * Whether the combine process should be executed after the process function receives
             * watermarks from both upstream channels.
             */
            public BoolWatermarkBuilder combineWaitForAllChannels(
                    boolean combineWaitForAllChannels) {
                this.combineWaitForAllChannels = combineWaitForAllChannels;
                return this;
            }

            public BoolWatermarkDeclaration build() {
                return new BoolWatermarkDeclaration(
                        identifier,
                        new WatermarkCombinationPolicy(
                                this.combinationFunction, this.combineWaitForAllChannels),
                        this.defaultHandlingStrategy);
            }
        }
    }
}
```

### Emit Watermark

#### Emit watermark from process function

To emit _**watermark**_ from _**Process Function**_ , we introduce _**`WatermarkManager`**_ interface and add it to _**`NonPartitionedContext`**_.

```java
/**
 * The {@link WatermarkManager} interface provides a mechanism to emit watermarks
 * from a process function.
 */
@Experimental
public interface WatermarkManager {

    /**
     * Emits a watermark from the process function.
     *
     * @param watermark the {@link GeneralizedWatermark} to emit.
     */
    void emitWatermark(Watermark watermark);
}
```

```java
@Experimental
public interface NonPartitionedContext<OUT> extends AbstractPartitionedContext {
    ...

    /** Get {@link WatermarkManager} instance, which allow emitting a {@link Watermark} from the process function. */
    WatermarkManager getWatermarkManager();
  
    ...
}
```

By the way, we also want to add a method for getting _**`NonPartitionedContext`**_ _**from**_ from _**`PartitionedContext`**_. This allow user emit _**watermark**_ in a context with partition.

```java
@Experimental
public interface PartitionedContext extends RuntimeContext {
    ...
      /** Get the non-partitioned context of process function. */
    NonPartitionedContext<?> getNonPartitionedContext();

    ...
}
```

#### Emit watermark from source

For sources we only allow the connector developers (and not users) to send watermarks. So we enable the ability to send a _**watermark**_ in _**`SourceReaderContext`**_.

```java
/** The interface that exposes some context from runtime to the {@link SourceReader}. */
@Public
public interface SourceReaderContext {
    ...

    /**
     * Send the watermark to source output.
     *
     * <p>This should only be used for datastream v2.
     */
    void emitWatermark(Watermark watermark);
  
    ...
}
```

### Combine Watermarks

An _**Process Function**_ may have multiple upstream inputs, and each input may have multiple degrees of parallelism. As a result, _**Process Function**_ has the opportunity to receive _**watermark**_ from several different channels. However, considering the semantic of watermark itself, we often want to combine/merge _**watermark**_ from various channels before output to the function. 

The channel from which the data comes is not known to the process function, so the combination logic must be provided by the watermark implementation itself. We provide the following combination strategies:

```java
/**
 * The {@link WatermarkCombinationFunction} defines the comparison/combination semantics among
 * {@link Watermark}s.
 */
@Experimental
public interface WatermarkCombinationFunction extends Function {
    /**
     * The {@link BoolWatermarkCombinationFunction} enum defines the combination semantics for
     * boolean watermarks. It includes logical operations such as {@code OR} and {@code AND}.
     */
    @Experimental
    enum BoolWatermarkCombinationFunction implements WatermarkCombinationFunction {
        /** Logical OR combination for boolean watermarks. */
        OR,

        /** Logical AND combination for boolean watermarks. */
        AND
    }

    /**
     * The {@link NumericWatermarkCombinationFunction} enum defines the combination semantics for
     * numeric watermarks. It includes operations such as {@code MIN} and {@code MAX}.
     */
    @Experimental
    enum NumericWatermarkCombinationFunction implements WatermarkCombinationFunction {
        /** Minimum value combination for numeric watermarks. */
        MIN,

        /** Maximum value combination for numeric watermarks. */
        MAX
    }
}
```

For an Input, if only some of its channels receive _**watermark**_ , the watermark corresponding to the channel that does not receive is undefined. When doing the combine in this case, we offer two strategies:

  * According to the combination function, decide the default value for the channel that does not receive any watermark, for example, _`Long.MIN_VALUE`_ is the default value used for _**LongWatermark**_ _combineFunctionMax_.

  * Combine only after all channels have received its first watermark.

Therefore, besides _**WatermarkCombinationFunction**_ , We also introduced a Boolean variable to control the two kinds of behavior.

```java
/**
 * The {@link WatermarkCombinationPolicy} defines when and how to the combine {@link Watermark}s.
 */
@Experimental
public class WatermarkCombinationPolicy implements Serializable {

    private static final long serialVersionUID = 1L;

    private WatermarkCombinationFunction watermarkCombinationFunction;

    private boolean combineWaitForAllChannels;

    public WatermarkCombinationPolicy(
            WatermarkCombinationFunction watermarkCombinationFunction,
            boolean combineWaitForAllChannels) {
        this.watermarkCombinationFunction = watermarkCombinationFunction;
        this.combineWaitForAllChannels = combineWaitForAllChannels;
    }

    public WatermarkCombinationFunction getWatermarkCombinationFunction() {
        return watermarkCombinationFunction;
    }

    public boolean isCombineWaitForAllChannels() {
        return combineWaitForAllChannels;
    }
}
```

### Handle Watermarks in Process Function

Different from combining _**watermark**_ between channels, _**Process Function**_ is aware of which Input the watermark comes from. So the watermarks from multiple inputs should be handled by _**Process Function**_ or runtime framework.

We introduced corresponding **_`onWatermark`_** method to all type of _**Process Function**_ , which will be used as a callback when _**watermark**_ is received from a single input, and its return value is an enum class indicating whether the watermark's ownership is transferred to _**Process Function**_.

The handling strategy between inputs depends on the logic of the _**Process Function**_ itself. For most functions, we may only need the same strategy: Forwarding it to downstream or not. Therefore, we will allow the user to define the default handling strategy, and the framework uses it to handle watermarks when `_**onWatermark**_ `returns _**`WatermarkHandlingResult.PEEK`**_.

```java
/** This class defines watermark handling result for process function. */
public enum WatermarkHandlingResult {
    /** Process function only peek the watermark, and it's framework's responsibility to handle this watermark. */
    PEEK,
    /** This watermark should be sent to downstream by process function itself. The framework does no additional processing. */
    POLL,
}
```

```java
/**
 * This class defines the framework's behavior when the user-defined {@link Watermark} process method returns {@link
 * WatermarkHandlingResult#PEEK}.
 */
@Experimental
public enum WatermarkHandlingStrategy {
    /** The framework shouldn't take any action. */
    IGNORE,

    /** The framework should send the watermark to downstream. */
    FORWARD,
}
```

#### OneInputStreamProcessFunction

```java
/** 
* This contains all logical related to process records from single input. 
*/
@Experimental
public interface OneInputStreamProcessFunction<IN, OUT> extends ProcessFunction {

  ...

    /** Callback function when receive watermark. */
    default WatermarkHandlingResult onWatermark(
            Watermark watermark, Collector<OUT> output, NonPartitionedContext<OUT> ctx) {
      return WatermarkHandlingResult.PEEK;
     }

  ...
  
}
```

#### TwoInputBroadcastStreamProcessFunction

Note: In the case of two inputs, it is up to the user to ensure that the same _**watermark**_ on two inputs is not incorrectly processed. For example, if the _**watermark**_ of Input1 is processed by the UDF and Input2 is handled by the framework, the correctness of the result is not guaranteed.

```java
/**
 * This contains all logical related to process records from a broadcast stream and a non-broadcast
 * stream.
 */
@Experimental
public interface TwoInputBroadcastStreamProcessFunction<IN1, IN2, OUT> extends ProcessFunction {

    ...
  
    /**
     * Callback function when receive the watermark from broadcast input
     *
     * @param watermark to process.
     * @param output to emit record.
     * @param ctx, runtime context in which this function is executed.
     */
    default WatermarkHandlingResult onWatermarkFromBroadcastInput(
            Watermark watermark,
            Collector<OUT> output,
            NonPartitionedContext<OUT> ctx) {
      return WatermarkHandlingResult.PEEK;
    }

    /**
     * Callback function when receive the watermark from non-broadcast input
     *
     * @param watermark to process.
     * @param output to emit record.
     * @param ctx, runtime context in which this function is executed.
     */
    default WatermarkHandlingResult onWatermarkFromNonBroadcastInput(
            Watermark watermark, Collector<OUT> output, NonPartitionedContext<OUT> ctx) {
      return WatermarkHandlingResult.PEEK;
    }

   ...
  
}
```

#### TwoInputNonBroadcastStreamProcessFunction

```java
/** This contains all logical related to process records from two non-broadcast input. */
@Experimental
public interface TwoInputNonBroadcastStreamProcessFunction<IN1, IN2, OUT> extends ProcessFunction {

    ...
  
    /**
     * Callback function when receive the watermark from the first input
     *
     * @param watermark to process.
     * @param output to emit record.
     * @param ctx, runtime context in which this function is executed.
     */
    default WatermarkHandlingResult onWatermarkFromFirstInput(
            Watermark watermark,
            Collector<OUT> output,
            NonPartitionedContext<OUT> ctx) {
      return WatermarkHandlingResult.PEEK;
    }

    /**
     * Callback function when receive the watermark from the second input
     *
     * @param watermark to process.
     * @param output to emit record.
     * @param ctx, runtime context in which this function is executed.
     */
    default WatermarkHandlingResult onWatermarkFromSecondInput(
            Watermark watermark,
            Collector<OUT> output,
            NonPartitionedContext<OUT> ctx) {
      return WatermarkHandlingResult.PEEK;
    }

  ...
  
}
```

#### TwoOutputStreamProcessFunction

```java
/** This contains all logical related to process and emit records to two output streams. */
@Experimental
public interface TwoOutputStreamProcessFunction<IN, OUT1, OUT2> extends ProcessFunction {

     ...
    
    /**
     * Callback function when receive the watermark from the input.
     *
     * @param watermark to process.
     * @param output1 to emit data to the first output.
     * @param output2 to emit data to the second output.
     * @param ctx, runtime context in which this function is executed.
     */
    default WatermarkHandlingResult onWatermark(
            Watermark watermark,
            Collector<OUT1> output1,
            Collector<OUT2> output2,
            TwoOutputNonPartitionedContext<OUT1, OUT2> ctx) {
        return WatermarkHandlingResult.PEEK;
    }

    ...
  
}
```

# Compatibility, Deprecation, and Migration Plan

1\. The contents described in this FLIP will make sure to be orthogonal to existing _**Watermark**_ s and all the existing tests should pass, no compatibility issues will be introduced. 

2.The proposed public interfaces in this FLIP will be annotated by _**@Experimental**_ first, and should be changed to _**@PublicEvolving**_ /_**@Public**_ along with other Datastream V2 APIs.


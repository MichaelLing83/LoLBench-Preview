> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

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


### Implementation Guidance

1. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/Watermark.java` defining `Watermark` with functions `Watermark.getIdentifier`. Defines the base `Watermark` interface with an identifier method, as specified by the FLIP's watermark abstraction.

2. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermark.java` defining `BoolWatermark` with functions `BoolWatermark.BoolWatermark`, `BoolWatermark.getValue`, `BoolWatermark.getIdentifier`, `BoolWatermark.equals`, `BoolWatermark.hashCode`, and `BoolWatermark.toString`. Implements the `Watermark` interface for boolean-valued watermarks with an identifier and boolean value, as described in the "two types" part of the section.

3. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermark.java` defining `LongWatermark` with functions `LongWatermark.LongWatermark`, `LongWatermark.getValue`, `LongWatermark.getIdentifier`, `LongWatermark.equals`, `LongWatermark.hashCode`, and `LongWatermark.toString`. Implements the `Watermark` interface for long-valued watermarks with an identifier and long value, as described in the "two types" part of the section.

**Supporting changes:**

1. In `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/api/serialization/EventSerializer.java`, update `EventSerializer.toSerializedEvent` and `EventSerializer.fromSerializedEvent`. Serializer must be extended to handle the new WatermarkEvent type.

2. In `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/buffer/Buffer.java`, update `DataType.getDataType`. Buffer type enum must include the new WatermarkEvent data type.

3. Add `flink-runtime/src/main/java/org/apache/flink/runtime/event/WatermarkEvent.java` defining `WatermarkEvent` with functions `WatermarkEvent.WatermarkEvent`, `WatermarkEvent.write`, `WatermarkEvent.read`, `WatermarkEvent.getWatermark`, `WatermarkEvent.isAligned`, `WatermarkEvent.equals`, `WatermarkEvent.hashCode`, and `WatermarkEvent.toString`. Runtime event wrapper for serializing and transmitting generalized watermarks through the Flink network stack; supports the watermark propagation described in this section but is not part of the public `Watermark` value API.
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


### Implementation Guidance

1. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclaration.java` defining `WatermarkDeclaration` with functions `WatermarkDeclaration.getIdentifier`. Defines the base `WatermarkDeclaration` interface as specified, declaring the contract for watermark declarations.

2. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/BoolWatermarkDeclaration.java` defining `BoolWatermarkDeclaration` with functions `BoolWatermarkDeclaration.BoolWatermarkDeclaration`, `BoolWatermarkDeclaration.getIdentifier`, `BoolWatermarkDeclaration.newWatermark`, `BoolWatermarkDeclaration.getCombinationPolicy`, `BoolWatermarkDeclaration.getDefaultHandlingStrategy`, `BoolWatermarkDeclaration.equals`, `BoolWatermarkDeclaration.hashCode`, and `BoolWatermarkDeclaration.toString`. Implements the declaration for `BoolWatermark` with combination policy and handling strategy, as specified.

3. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/LongWatermarkDeclaration.java` defining `LongWatermarkDeclaration` with functions `LongWatermarkDeclaration.LongWatermarkDeclaration`, `LongWatermarkDeclaration.getIdentifier`, `LongWatermarkDeclaration.newWatermark`, `LongWatermarkDeclaration.getCombinationPolicy`, `LongWatermarkDeclaration.getDefaultHandlingStrategy`, `LongWatermarkDeclaration.equals`, `LongWatermarkDeclaration.hashCode`, and `LongWatermarkDeclaration.toString`. Implements the declaration for `LongWatermark` with combination policy and handling strategy, as specified.

4. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkDeclarations.java` defining `WatermarkDeclarations`, `WatermarkDeclarationBuilder`, `LongWatermarkDeclarationBuilder`, and `BoolWatermarkDeclarationBuilder` with functions `WatermarkDeclarations.newBuilder`, `WatermarkDeclarationBuilder.WatermarkDeclarationBuilder`, `WatermarkDeclarationBuilder.typeLong`, `WatermarkDeclarationBuilder.typeBool`, `LongWatermarkDeclarationBuilder.LongWatermarkDeclarationBuilder`, `LongWatermarkDeclarationBuilder.combineFunctionMax`, `LongWatermarkDeclarationBuilder.combineFunctionMin`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategy`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategyForward`, `LongWatermarkDeclarationBuilder.defaultHandlingStrategyIgnore`, `LongWatermarkDeclarationBuilder.combineWaitForAllChannels`, `LongWatermarkDeclarationBuilder.build`, `BoolWatermarkDeclarationBuilder.BoolWatermarkDeclarationBuilder`, `BoolWatermarkDeclarationBuilder.combineFunctionOR`, `BoolWatermarkDeclarationBuilder.combineFunctionAND`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategy`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategyForward`, `BoolWatermarkDeclarationBuilder.defaultHandlingStrategyIgnore`, `BoolWatermarkDeclarationBuilder.combineWaitForAllChannels`, and `BoolWatermarkDeclarationBuilder.build`. Provides the builder utility for constructing `WatermarkDeclaration` instances, corresponding to the "build tool" described in the section.

5. In `flink-core/src/main/java/org/apache/flink/api/connector/source/Source.java`, update `Source.declareWatermarks`. Adds the `watermarkDeclarations` method to the `Source` interface so that sources can declare their watermarks, as specified by "Watermark from Source.".

6. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamConfig.java`, update `StreamConfig.setWatermarkDeclarations` and `StreamConfig.getWatermarkDeclarations`. Adds configuration keys and methods for serializing/deserializing watermark declarations in the stream graph, enabling the runtime to access declarations at execution time.

**Supporting changes:**

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/ProcessFunction.java`, update `ProcessFunction.declareWatermarks`. `ProcessFunction` must expose the `watermarkDeclarations` method to declare watermarks from process functions.

2. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/ExecutionEnvironmentImpl.java`, update `ExecutionEnvironmentImpl.fromSource`. Execution environment wiring must be updated to propagate watermark declarations.

3. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraph.java`, update `StreamGraph.serializeAndSaveWatermarkDeclarations` and `StreamGraph.getSerializedWatermarkDeclarations`. Stream graph must store and propagate watermark declarations for each node.

4. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java`, update `StreamGraphGenerator.generate`. Stream graph generator must extract watermark declarations during graph construction.

5. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamNode.java`, update `StreamNode.getOperator`. Stream node must support watermark declaration fields.

6. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/graph/StreamingJobGraphGenerator.java`, update `StreamingJobGraphGenerator.createChain`. Job graph generator must serialize watermark declarations into job vertex config.

7. Add `flink-runtime/src/main/java/org/apache/flink/streaming/util/watermark/WatermarkUtils.java` defining `WatermarkUtils` with functions `WatermarkUtils.getInternalWatermarkDeclarationsFromStreamGraph`, `WatermarkUtils.getWatermarkDeclarations`, and `WatermarkUtils.convertToInternalWatermarkDeclarations`. Utility class for resolving and merging watermark declarations across the stream topology.
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


### Implementation Guidance

1. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkManager.java` defining `WatermarkManager` with functions `WatermarkManager.emitWatermark`. Defines the `WatermarkManager` interface for emitting watermarks, as specified.

2. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/NonPartitionedContext.java`, update `NonPartitionedContext.getWatermarkManager`. Adds `getWatermarkManager` method to `NonPartitionedContext`, as specified.

3. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/PartitionedContext.java`, update `PartitionedContext.getStateManager`, `PartitionedContext.getProcessingTimeManager`, and `PartitionedContext.getNonPartitionedContext`. Refactored to extend `BasePartitionedContext`, enabling access to `NonPartitionedContext` for watermark emission from partitioned contexts.

4. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputNonPartitionedContext.java`, update `TwoOutputNonPartitionedContext.getWatermarkManager`. Adds `getWatermarkManager` for two-output contexts, parallel to the `NonPartitionedContext` change.

5. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/TwoOutputPartitionedContext.java` defining `TwoOutputPartitionedContext` with functions `TwoOutputPartitionedContext.getNonPartitionedContext`. New two-output partitioned context interface enabling access to `NonPartitionedContext` in two-output scenarios.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/watermark/DefaultWatermarkManager.java` defining `DefaultWatermarkManager` with functions `DefaultWatermarkManager.DefaultWatermarkManager` and `DefaultWatermarkManager.emitWatermark`. Runtime implementation of `WatermarkManager` that emits watermark events to the output.

**Supporting changes:**

1. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/AbstractPartitionedContext.java` defining `AbstractPartitionedContext` with functions `AbstractPartitionedContext.AbstractPartitionedContext`, `AbstractPartitionedContext.getJobInfo`, `AbstractPartitionedContext.getTaskInfo`, `AbstractPartitionedContext.getStateManager`, `AbstractPartitionedContext.getProcessingTimeManager`, and `AbstractPartitionedContext.getMetricGroup`. Runtime base class for partitioned context implementations must be created to support the new context hierarchy.

2. Add `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/context/BasePartitionedContext.java` defining `BasePartitionedContext` with functions `BasePartitionedContext.getStateManager` and `BasePartitionedContext.getProcessingTimeManager`. New base interface added so `PartitionedContext` and `TwoOutputPartitionedContext` can share state/processing-time accessors; the section is about watermark emission via `getNonPartitionedContext`, which lives on the subinterfaces.

3. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultNonPartitionedContext.java`, update `DefaultNonPartitionedContext.DefaultNonPartitionedContext` and `DefaultNonPartitionedContext.getWatermarkManager`. Default implementation must be updated to provide `WatermarkManager` access.

4. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultPartitionedContext.java`, update `DefaultPartitionedContext.DefaultPartitionedContext`, `DefaultPartitionedContext.getJobInfo`, `DefaultPartitionedContext.getTaskInfo`, `DefaultPartitionedContext.getStateManager`, `DefaultPartitionedContext.getProcessingTimeManager`, `DefaultPartitionedContext.setNonPartitionedContext`, `DefaultPartitionedContext.getMetricGroup`, and `DefaultPartitionedContext.getNonPartitionedContext`. Default implementation must be refactored to extend the new abstract base and expose `NonPartitionedContext`.

5. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputNonPartitionedContext.java`, update `DefaultTwoOutputNonPartitionedContext.DefaultTwoOutputNonPartitionedContext` and `DefaultTwoOutputNonPartitionedContext.getWatermarkManager`. Default two-output implementation must be updated to provide `WatermarkManager` access.

6. Add `flink-datastream/src/main/java/org/apache/flink/datastream/impl/context/DefaultTwoOutputPartitionedContext.java` defining `DefaultTwoOutputPartitionedContext` with functions `DefaultTwoOutputPartitionedContext.DefaultTwoOutputPartitionedContext`, `DefaultTwoOutputPartitionedContext.setNonPartitionedContext`, and `DefaultTwoOutputPartitionedContext.getNonPartitionedContext`. Default two-output partitioned context implementation must be created for the new context interface.
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


### Implementation Guidance

1. In `flink-core/src/main/java/org/apache/flink/api/connector/source/SourceReaderContext.java`, update `SourceReaderContext.emitWatermark`. Adds the `emitWatermark(Watermark)` method to the interface, as specified.

2. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperator.java`, update `SourceOperator.SourceOperator`, `SourceOperator.initReader`, and `SourceOperator.emitWatermark`. Implements watermark emission logic in the source operator, wiring `SourceReaderContext.emitWatermark` to the output.

3. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/SourceOperatorFactory.java`, update `SourceOperatorFactory.createStreamOperator`, `SourceOperatorFactory.getSourceWatermarkDeclarations`, and `SourceOperatorFactory.instantiateSourceOperator`. Updates the factory to configure watermark declarations from the `Source` and pass them to the operator, enabling watermark emission at runtime.

**Supporting changes:**

1. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/SourceOperatorStreamTask.java`, update `AsyncDataOutputToOutput.emitWatermark`. Stream task must propagate watermark declarations to the source operator.
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


### Implementation Guidance

1. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationFunction.java` defining `WatermarkCombinationFunction`, `BoolWatermarkCombinationFunction`, and `NumericWatermarkCombinationFunction`. Defines the `WatermarkCombinationFunction` interface with built-in strategies (MIN, MAX, AND, OR), as specified.

2. Add `flink-core-api/src/main/java/org/apache/flink/api/common/watermark/WatermarkCombinationPolicy.java` defining `WatermarkCombinationPolicy` with functions `WatermarkCombinationPolicy.WatermarkCombinationPolicy`, `WatermarkCombinationPolicy.getWatermarkCombinationFunction`, `WatermarkCombinationPolicy.isCombineWaitForAllChannels`, `WatermarkCombinationPolicy.equals`, and `WatermarkCombinationPolicy.hashCode`. Defines the `WatermarkCombinationPolicy` class with the boolean `waitForAllChannels` flag, implementing the two alignment strategies described in the section.

3. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AbstractInternalWatermarkDeclaration.java` defining `AbstractInternalWatermarkDeclaration` with functions `AbstractInternalWatermarkDeclaration.AbstractInternalWatermarkDeclaration`, `AbstractInternalWatermarkDeclaration.getIdentifier`, `AbstractInternalWatermarkDeclaration.newWatermark`, `AbstractInternalWatermarkDeclaration.getCombinationPolicy`, `AbstractInternalWatermarkDeclaration.getDefaultHandlingStrategy`, `AbstractInternalWatermarkDeclaration.isAligned`, `AbstractInternalWatermarkDeclaration.createWatermarkCombiner`, and `AbstractInternalWatermarkDeclaration.from`. Internal base class for watermark declarations that carry combination semantics.

4. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/Alignable.java` defining `Alignable` with functions `Alignable.isAligned`. Interface for declarations that support alignment (waiting for all channels), implementing the "combine only after all channels" strategy.

5. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableBoolWatermarkDeclaration.java` defining `AlignableBoolWatermarkDeclaration` with functions `AlignableBoolWatermarkDeclaration.AlignableBoolWatermarkDeclaration` and `AlignableBoolWatermarkDeclaration.isAligned`. Alignable variant of `BoolWatermarkDeclaration` for the wait-for-all-channels strategy.

6. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignableLongWatermarkDeclaration.java` defining `AlignableLongWatermarkDeclaration` with functions `AlignableLongWatermarkDeclaration.AlignableLongWatermarkDeclaration` and `AlignableLongWatermarkDeclaration.isAligned`. Alignable variant of `LongWatermarkDeclaration` for the wait-for-all-channels strategy.

7. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/AlignedWatermarkCombiner.java` defining `AlignedWatermarkCombiner` with functions `AlignedWatermarkCombiner.AlignedWatermarkCombiner` and `AlignedWatermarkCombiner.combineWatermark`. Combiner implementation that waits for all channels before combining, implementing the second alignment strategy.

8. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/BoolWatermarkCombiner.java` defining `BoolWatermarkCombiner` with functions `BoolWatermarkCombiner.BoolWatermarkCombiner`, `BoolWatermarkCombiner.combineWatermark`, and `BoolWatermarkCombiner.shouldEmitWatermark`. Combiner implementation for `BoolWatermark` using AND/OR combination functions with default value or aligned semantics.

9. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalBoolWatermarkDeclaration.java` defining `InternalBoolWatermarkDeclaration` with functions `InternalBoolWatermarkDeclaration.InternalBoolWatermarkDeclaration`, `InternalBoolWatermarkDeclaration.newWatermark`, and `InternalBoolWatermarkDeclaration.createWatermarkCombiner`. Internal runtime declaration for bool watermarks that creates the appropriate combiner.

10. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/InternalLongWatermarkDeclaration.java` defining `InternalLongWatermarkDeclaration` with functions `InternalLongWatermarkDeclaration.InternalLongWatermarkDeclaration`, `InternalLongWatermarkDeclaration.newWatermark`, and `InternalLongWatermarkDeclaration.createWatermarkCombiner`. Internal runtime declaration for long watermarks that creates the appropriate combiner.

11. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/LongWatermarkCombiner.java` defining `LongWatermarkCombiner` and `LongWatermarkElement` with functions `LongWatermarkCombiner.LongWatermarkCombiner`, `LongWatermarkCombiner.combineWatermark`, `LongWatermarkCombiner.shouldEmitWatermark`, `LongWatermarkElement.LongWatermarkElement`, `LongWatermarkElement.getInternalIndex`, `LongWatermarkElement.setInternalIndex`, `LongWatermarkElement.setWatermarkValue`, and `LongWatermarkElement.getWatermarkValue`. Combiner implementation for `LongWatermark` using MIN/MAX combination functions with default value or aligned semantics.

12. Add `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermark/WatermarkCombiner.java` defining `WatermarkCombiner` with functions `WatermarkCombiner.combineWatermark`. Base interface for all watermark combiner implementations.

13. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/AbstractStreamTaskNetworkInput.java`, update `AbstractStreamTaskNetworkInput.AbstractStreamTaskNetworkInput`, `AbstractStreamTaskNetworkInput.emitNext`, `AbstractStreamTaskNetworkInput.processEvent`, and `AbstractStreamTaskNetworkInput.processWatermarkEvent`. Core integration point where generalized watermark events are intercepted from the network and dispatched to combiners.

14. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInput.java`, update `StreamTaskNetworkInput.StreamTaskNetworkInput`. Concrete network input implementation updated to instantiate and wire watermark combiners from declarations.

**Supporting changes:**

1. In `flink-runtime/pom.xml`, apply the required changes. Build dependency must be added for watermark combiner test utilities.

2. In `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/InputGate.java`, update `InputGate.resumeGateConsumption`. Input gate interface must expose channel count for combiner initialization.

3. In `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/SingleInputGate.java`, update `SingleInputGate.resumeGateConsumption`. Implementation must provide channel count for combiner initialization.

4. In `flink-runtime/src/main/java/org/apache/flink/runtime/io/network/partition/consumer/UnionInputGate.java`, update `UnionInputGate.resumeGateConsumption`. Union gate implementation must provide channel count for combiner initialization.

5. In `flink-runtime/src/main/java/org/apache/flink/runtime/taskmanager/InputGateWithMetrics.java`, update `InputGateWithMetrics.resumeGateConsumption`. Metrics wrapper must delegate the new channel count method.

6. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/MultiInputSortingDataInput.java`, update `SortingPhaseDataOutput.emitWatermark`. Sorting input must handle watermark events during sort processing.

7. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/sort/SortingDataInput.java`, update `ForwardingDataOutput.emitWatermark`. Sorting input must handle watermark events during sort processing.

8. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamMultipleInputProcessorFactory.java`, update `StreamMultipleInputProcessorFactory.create` and `StreamTaskNetworkOutput.emitWatermark`. Multi-input processor factory must pass watermark declarations to network inputs.

9. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTaskNetworkInputFactory.java`, update `StreamTaskNetworkInputFactory.create`. Factory must accept and propagate watermark declarations.

10. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/StreamTwoInputProcessorFactory.java`, update `StreamTwoInputProcessorFactory.create` and `StreamTaskNetworkOutput.emitWatermark`. Two-input processor factory must pass watermark declarations to network inputs.

11. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/checkpointing/CheckpointedInputGate.java`, update `CheckpointedInputGate.resumeGateConsumption`. Checkpointed gate must delegate the new channel count method.

12. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/io/recovery/RescalingStreamTaskNetworkInput.java`, update `RescalingStreamTaskNetworkInput.processEvent`. Rescaling input must be updated for the new network input constructor.

13. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/tasks/OneInputStreamTask.java`, update `OneInputStreamTask.createTaskInput` and `StreamTaskNetworkOutput.emitWatermark`. One-input stream task must pass watermark declarations when creating network inputs.

14. In `flink-runtime/src/main/java/org/apache/flink/streaming/runtime/watermarkstatus/HeapPriorityQueue.java`, update `PriorityComparator` and `HeapPriorityQueueElement`. Priority queue visibility change needed for watermark combiner reuse.

15. In `pom.xml`, apply the required changes. Root POM must include new dependency versions used by watermark combiners.
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


### Implementation Guidance

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/OneInputStreamProcessFunction.java`, update `OneInputStreamProcessFunction.onWatermark`. Adds the `onWatermark` method with `WatermarkHandlingResult` return type, as specified in the Java code block.

**Supporting changes:**

1. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedProcessOperator.java`, update `KeyedProcessOperator.getNonPartitionedContext`. Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed one-input operator can route generalized-watermark callbacks; does not itself invoke `onWatermark`.

2. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/ProcessOperator.java`, update `ProcessOperator.open`, `ProcessOperator.processWatermarkInternal`, and `ProcessOperator.getNonPartitionedContext`. Non-keyed process operator must invoke the new `onWatermark` callback and implement watermark handling strategy.

3. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/KeyedProcessOperator.java`, update `KeyedProcessOperator.processWatermark`. Runtime keyed process operator must handle generalized watermark events.
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


### Implementation Guidance

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputBroadcastStreamProcessFunction.java`, update `TwoInputBroadcastStreamProcessFunction.onWatermarkFromBroadcastInput` and `TwoInputBroadcastStreamProcessFunction.onWatermarkFromNonBroadcastInput`. Adds `onWatermarkFromBroadcastInput` and `onWatermarkFromNonBroadcastInput` methods with `WatermarkHandlingResult` return type, as specified.

**Supporting changes:**

1. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputBroadcastProcessOperator.java`, update `KeyedTwoInputBroadcastProcessOperator.getNonPartitionedContext`. Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-input broadcast operator can route generalized-watermark callbacks; does not itself invoke the callbacks.

2. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputBroadcastProcessOperator.java`, update `TwoInputBroadcastProcessOperator.open`, `TwoInputBroadcastProcessOperator.processWatermark1Internal`, `TwoInputBroadcastProcessOperator.processWatermark2Internal`, and `TwoInputBroadcastProcessOperator.getNonPartitionedContext`. Two-input broadcast operator must invoke the new watermark callbacks and implement handling strategy.

3. In `flink-runtime/src/main/java/org/apache/flink/streaming/api/operators/TwoInputStreamOperator.java`, update `TwoInputStreamOperator.processWatermark1` and `TwoInputStreamOperator.processWatermark2`. Two-input operator interface must support generalized watermark processing on both inputs.
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


### Implementation Guidance

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoInputNonBroadcastStreamProcessFunction.java`, update `TwoInputNonBroadcastStreamProcessFunction.onWatermarkFromFirstInput` and `TwoInputNonBroadcastStreamProcessFunction.onWatermarkFromSecondInput`. Adds `onWatermarkFromFirstInput` and `onWatermarkFromSecondInput` methods with `WatermarkHandlingResult` return type, as specified.

**Supporting changes:**

1. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoInputNonBroadcastProcessOperator.java`, update `KeyedTwoInputNonBroadcastProcessOperator.getNonPartitionedContext`. Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-input non-broadcast operator can route generalized-watermark callbacks; does not itself invoke the callbacks.

2. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoInputNonBroadcastProcessOperator.java`, update `TwoInputNonBroadcastProcessOperator.open`, `TwoInputNonBroadcastProcessOperator.processWatermark1Internal`, `TwoInputNonBroadcastProcessOperator.processWatermark2Internal`, and `TwoInputNonBroadcastProcessOperator.getNonPartitionedContext`. Two-input non-broadcast operator must invoke the new watermark callbacks and implement handling strategy.
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


### Implementation Guidance

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputStreamProcessFunction.java`, update `TwoOutputStreamProcessFunction.onWatermark`, `TwoOutputStreamProcessFunction.processRecord`, and `TwoOutputStreamProcessFunction.onProcessingTimer`. Adds the `onWatermark` method with `WatermarkHandlingResult` return type for two-output process functions, as specified.

**Supporting changes:**

1. In `flink-datastream-api/src/main/java/org/apache/flink/datastream/api/function/TwoOutputApplyPartitionFunction.java`, update `TwoOutputApplyPartitionFunction.apply`. Two-output apply partition function must be updated for consistency with the new watermark callback pattern.

2. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/KeyedTwoOutputProcessOperator.java`, update `KeyedTwoOutputProcessOperator.getNonPartitionedContext`. Exposes the non-partitioned context through `getNonPartitionedContext` so the keyed two-output operator can route generalized-watermark callbacks; does not itself invoke the callback.

3. In `flink-datastream/src/main/java/org/apache/flink/datastream/impl/operators/TwoOutputProcessOperator.java`, update `TwoOutputProcessOperator.open`, `TwoOutputProcessOperator.processWatermarkInternal`, and `TwoOutputProcessOperator.getNonPartitionedContext`. Two-output operator must invoke the new watermark callback and implement handling strategy.
# Compatibility, Deprecation, and Migration Plan

1\. The contents described in this FLIP will make sure to be orthogonal to existing _**Watermark**_ s and all the existing tests should pass, no compatibility issues will be introduced. 

2.The proposed public interfaces in this FLIP will be annotated by _**@Experimental**_ first, and should be changed to _**@PublicEvolving**_ /_**@Public**_ along with other Datastream V2 APIs.

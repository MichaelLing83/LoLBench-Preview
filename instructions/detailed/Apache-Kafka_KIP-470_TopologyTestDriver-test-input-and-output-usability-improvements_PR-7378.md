> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# KIP-470: TopologyTestDriver test input and output usability improvements

# Motivation

This KIP is inspired by the Discussion in 

The stream application code is very compact and the test code is a lot of bigger code base than actual implementation of the application, that's why it would be good to get test code easily readable and understandable and that way also maintainable.

The proposal in  was to add alternate way to input and output topic, but this KIP enhance those classes and deprecate old functionality to make clear interface for test writer to use.

When using the old TopologyTestDriver you need to call ConsumerRecordFactory to create ConsumerRecord passed into pipeInput method to write to topic. Also when calling readOutput to consume from topic, you need to provide correct Deserializers each time.

You easily end up writing helper methods in your test classes, but this can be avoided when adding generic input and output topic classes to implement the needed functionality.

Also the logic of the old TopologyTestDriver is confusing, when you need to pipe ConsumerRecords to produce record to input topic and receive ProducerRecords when consuming from output topic.

Non-existing topic and no record in the queue scenarious are modified to throw Exception instead of returning null.

# Public Interfaces

```java
package org.apache.kafka.streams;

public class TopologyTestDriver {
    public TopologyTestDriver(Topology topology, Properties config); // existing constructor
    @Deprecate public TopologyTestDriver(Topology topology, Properties config, long initialWallClockTimeMs);
    public TopologyTestDriver(Topology topology, Properties config, Instant initialWallClockTime);

    @Deprecate public void advanceWallClockTime(long advanceMs); // can trigger wall-clock-time punctuation
    public void advanceWallClockTime(Duration advance); // can trigger wall-clock-time punctuation

    //Deprecate old pipe and read methods
    @Deprecate public void pipeInput(ConsumerRecord<byte[], byte[]> record); // can trigger event-time punctuation
    @Deprecate public void pipeInput(List<ConsumerRecord<byte[], byte[]>> records); // can trigger event-time punctuation
    @Deprecate public ProducerRecord<byte[], byte[]> readOutput(String topic);
    @Deprecate public <K, V> ProducerRecord<K, V> readOutput(String topic, Deserializer<K> keyDeserializer, Deserializer<V> valueDeserializer);

    // methods for TestTopic object creation
    public final <K, V> TestOutputTopic<K, V> createOutputTopic(final String topicName, final Deserializer<K> keyDeserializer, final Deserializer<V> valueDeserializer);
    // Uses current system time as start timestamp. Auto-advance is disabled.
    public final <K, V> TestInputTopic<K, V> createInputTopic(final String topicName, final Serializer<K> keySerializer, final Serializer<V> valueSerializer);
    //Uses provided startTimestamp and autoAdvance duration for timestamp generation
    public final <K, V> TestInputTopic<K, V> createInputTopic(final String topicName, final Serializer<K> keySerializer, final Serializer<V> valueSerializer, final Instant startTimestamp, final Duration autoAdvance);

    ...
}
```

```java
package org.apache.kafka.streams;

public class TestInputTopic<K, V> {
    //Create by TopologyTestDriver, Constructors are package private

    //Timestamp handling
    //Record timestamp can be provided when piping input or use internally tracked time configured with parameters:
    //startTimestamp the initial timestamp for generated records, if not provided uses current system time as start timestamp.
    //autoAdvance the time increment per generated record, if not provided auto-advance is disabled.

    //Advances the internally tracked time.
    void advanceTime(final Duration advance);

    //Methods to pipe single record
    void pipeInput(final V value);
    void pipeInput(final K key, final V value);

    // Use provided timestamp, does not auto advance internally tracked time.
    void pipeInput(final V value, final Instant timestamp);
    void pipeInput(final K key, final V value, final Instant timestamp);

    // Method with long provided to support easier migration of old tests
    void pipeInput(final K key, final V value, final long timestampMs);

    // If record timestamp set, does not auto advance internally tracked time.
    void pipeInput(final TestRecord<K, V> record);

    //Methods to pipe list of records
    void pipeValueList(final List<V> values);
    void pipeKeyValueList(final List<KeyValue<K, V>> keyValues);

    // Use provided timestamp, does not auto advance internally tracked time.
    void pipeValueList(final List<V> values, final Instant startTimestamp, final Duration advanceMs);
    void pipeKeyValueList(final List<KeyValue<K, V>> keyValues, final Instant startTimestamp, final Duration advanceMs);

    // If record timestamp set, does not auto advance internally tracked time.
    void pipeRecordList(final List<? extends TestRecord<K, V>> records);
}
```

Both the `autoAdvance` increment passed to `createInputTopic` and the `advance` given to `TestInputTopic.advanceTime` must be non-negative; a negative `Duration` is rejected with `IllegalArgumentException`.

```java
package org.apache.kafka.streams;

public class TestOutputTopic<K, V> {
    //Create by TopologyTestDriver, Constructors are package private

    //Method to check queue size
    final long getQueueSize();
    final boolean isEmpty();

    //Methods to readOutput, throw NoSuchElement if no record in queue
    V readValue();
    KeyValue<K, V> readKeyValue();
    TestRecord<K, V> readRecord();

    //Output as collection
    List<V> readValuesToList();
    List<KeyValue<K, V>> readKeyValuesToList();
    Map<K, V> readKeyValuesToMap();
    List<TestRecord<K, V>> readRecordsToList();
}
```

Because `readKeyValuesToMap` collapses the output into a table keyed by the record key, it does not permit a null key and throws `NullPointerException` if one is encountered.

```java
package org.apache.kafka.streams.test;
public class TestRecord<K, V> {
    //Constructors
    public TestRecord(final V value);
    public TestRecord(final K key, final V value);
    public TestRecord(final K key, final V value, final Headers headers);
    public TestRecord(final K key, final V value, final Instant recordTime);
    public TestRecord(final K key, final V value, final Headers headers, final Instant recordTime);
    public TestRecord(final K key, final V value, final Headers headers, final Long timestamp);

    //Constructor based on existing record
    public TestRecord(final ConsumerRecord<K, V> record);
    public TestRecord(final ProducerRecord<K, V> record);

    // Methods like in ProducerRecord / ConsumerRecord
    public Headers headers();
    public K key();
    public V value();
    public Long timestamp();

    // Getters
    public Headers getHeaders();
    public K getKey();
    public V getValue();
    public Instant getRecordTime();

    //Overrides
    public String toString();
    public boolean equals(Object o);
    public int hashCode();
}
```

```java
package org.apache.kafka.streams.test;

//Recommended to use normal assertion library methods
@Deprecated
public class OutputVerifier {
    ...
}
```

```java
package org.apache.kafka.streams.test;

//Similar functionality now in TestInputTopic
@Deprecated
public class ConsumerRecordFactory<K, V> {
    ...
}
```


### Implementation Guidance

1. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java` defining `TestInputTopic`. Implements the `TestInputTopic<K, V>` class as specified, with typed `pipeInput`, `pipeValueList`, `pipeKeyValueList`, `pipeRecordList`, and `advanceTime` methods, replacing the untyped `ConsumerRecordFactory` + `pipeInput` workflow.

2. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java` defining `TestOutputTopic`. Implements the `TestOutputTopic<K, V>` class as specified, with typed `readValue`, `readKeyValue`, `readRecord`, and collection-read methods (`readValuesToList`, `readKeyValuesToList`, `readKeyValuesToMap`, `readRecordsToList`), plus queue inspection (`getQueueSize`, `isEmpty`).

3. In `streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java`, update `TopologyTestDriver`. Adds `createInputTopic` and `createOutputTopic` factory methods as specified, adds `Instant`-based constructor and `Duration`-based `advanceWallClockTime`, and deprecates the old `long`-based constructor and direct `pipeInput`/`readOutput` methods.

4. In `streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java`, update `ConsumerRecordFactory`. Marks the class `@Deprecated` as specified.

5. In `streams/test-utils/src/main/java/org/apache/kafka/streams/test/OutputVerifier.java`, update `OutputVerifier`. Marks the class `@Deprecated` as specified.

6. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java` defining `TestRecord`. Implements the `TestRecord<K, V>` value class as specified, with all constructors (value-only, key+value, headers, timestamp, from ConsumerRecord/ProducerRecord), accessors, and `equals`/`hashCode`/`toString` overrides.
# Proposed Changes

This improvement adds TestInputTopic class which replaces TopologyTestDriver and ConsumerRecordFactory methods as one class to be used to write to Input Topics and TestOutputTopic class which collects TopologyTestDriver reading methods and provide typesafe read methods.

```java
public class SimpleTopicTest {

  private TopologyTestDriver testDriver;
  private TestInputTopic<String, String> inputTopic;
  private TestOutputTopic<String, String> outputTopic;

  @Before
  public void setup() {
    testDriver = new TopologyTestDriver(TestStream.getTopology(), TestStream.getConfig());
    inputTopic = testDriver.createInputTopic(TestStream.INPUT_TOPIC, new StringSerializer(), new StringSerializer());
    outputTopic = testDriver.createOutputTopic(TestStream.OUTPUT_TOPIC, new StringDeserializer(), new LongDeserializer());
  }

  @After
  public void tearDown() {
      testDriver.close();
  }

  @Test
  public void testOneWord() {
    //Feed word "Hello" to inputTopic and no kafka key, timestamp is irrelevant in this case
    inputTopic.pipeInput("Hello");
    assertThat(outputTopic.readValue()).isEqualTo("Hello");
    //No more output in topic
    assertThat(outputTopic.isEmpty()).isTrue();
  }
}
```

  * New Example utilizing new classes test added to streams/examples/src/test/java/org/apache/kafka/streams/examples/wordcount/WordCountDemoTest.java

  * Examples in Testing Kafka Streams <https://kafka.apache.org/22/documentation/streams/developer-guide/testing.html> updated to use new TopolocyTestDriver, TestInputTopic and TestOutputTopic


### Implementation Guidance

1. In `docs/streams/developer-guide/testing.html`, apply the required changes. Updates the Kafka Streams testing developer guide to demonstrate the new `TestInputTopic`/`TestOutputTopic` API, as the section explicitly requests (`Examples in Testing Kafka Streams... updated to use new TopolocyTestDriver, TestInputTopic and TestOutputTopic`).

2. In `streams/examples/src/main/java/org/apache/kafka/streams/examples/wordcount/WordCountDemo.java`, update `WordCountDemo.main`, `WordCountDemo.getStreamsConfig`, and `WordCountDemo.createWordCountStream`. Extracts `getTopology` and `getStreamsConfig` as `static` package-private methods so that `WordCountDemoTest` can call them directly, enabling testability without running the full application.

3. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java` defining functions `TestInputTopic.TestInputTopic`, `TestInputTopic.advanceTime`, `TestInputTopic.getTimestampAndAdvanced`, `TestInputTopic.pipeInput`, `TestInputTopic.pipeRecordList`, `TestInputTopic.pipeKeyValueList`, `TestInputTopic.pipeValueList`, and `TestInputTopic.toString`. Adds the new `TestInputTopic<K, V>` class wrapping `TopologyTestDriver` with typed `pipeInput` methods that accept key/value pairs, `TestRecord` instances, or lists, replacing the need to manually create `ConsumerRecord` via `ConsumerRecordFactory`.

4. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java` defining functions `TestOutputTopic.TestOutputTopic`, `TestOutputTopic.readValue`, `TestOutputTopic.readKeyValue`, `TestOutputTopic.readRecord`, `TestOutputTopic.readRecordsToList`, `TestOutputTopic.readKeyValuesToMap`, `TestOutputTopic.readKeyValuesToList`, `TestOutputTopic.readValuesToList`, `TestOutputTopic.getQueueSize`, `TestOutputTopic.isEmpty`, and `TestOutputTopic.toString`. Adds the new `TestOutputTopic<K, V>` class wrapping `TopologyTestDriver` with typed `readRecord`, `readKeyValue`, `readValue`, `readKeyValuesToList`, and `readKeyValuesToMap` methods, replacing raw `ProducerRecord` reads and `OutputVerifier` assertions.

5. In `streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java`, update `TopologyTestDriver.TopologyTestDriver`, `TopologyTestDriver.pipeInput`, `TopologyTestDriver.pipeRecord`, `TopologyTestDriver.captureOutputRecords`, `TopologyTestDriver.advanceWallClockTime`, `TopologyTestDriver.readOutput`, `TopologyTestDriver.getRecordsQueue`, `TopologyTestDriver.createInputTopic`, `TopologyTestDriver.createOutputTopic`, `TopologyTestDriver.readRecord`, `TopologyTestDriver.getQueueSize`, and `TopologyTestDriver.isEmpty`. Adds `createInputTopic` and `createOutputTopic` factory methods returning `TestInputTopic`/`TestOutputTopic` instances. Adds internal `piping` and `reading` methods used by the new topic classes. Deprecates the old `pipeInput(ConsumerRecord)` and `readOutput(String)` methods.

6. In `streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java`, apply the required changes. Adds `@Deprecated` annotation to the entire class, directing users to use `TestInputTopic` instead.

7. Add `streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java` defining functions `TestRecord.TestRecord`, `TestRecord.headers`, `TestRecord.key`, `TestRecord.value`, `TestRecord.timestamp`, `TestRecord.getHeaders`, `TestRecord.getKey`, `TestRecord.getValue`, `TestRecord.getRecordTime`, `TestRecord.toString`, `TestRecord.equals`, and `TestRecord.hashCode`. Adds the new `TestRecord<K, V>` value class holding key, value, headers, and timestamp, used as the common record type for `TestInputTopic` and `TestOutputTopic`.

**Supporting changes:**

1. In `build.gradle`, apply the required changes. Build configuration adding hamcrest test dependency.
# Compatibility, Deprecation, and Migration Plan

 _There are no compatibility issues._

_The tests utilizing old TopologyTestDriver can still use deprecated methods._

# Rejected Alternatives

  * This is replacing 
  * Deprecate current TestTopologyDriver and move new to test package. This would have enabled to keep also TestInputTopic and TestOutputTopic classes in test package, not in very crowded streams root package.
  * Add ClientRecord interface to client package and modifiy ProducerRecord (and / or ConsumerRecord) to implement it, to be to utilize OutputVerifier with ProducerRecord and TestRecord

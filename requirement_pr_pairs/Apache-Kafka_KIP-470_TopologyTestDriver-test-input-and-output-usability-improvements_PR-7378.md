# Apache Kafka - KIP-470 TopologyTestDriver test input and output usability improvements

**PR:** https://github.com/apache/kafka/pull/7378
**Requirement Doc:** https://cwiki.apache.org/confluence/display/KAFKA/KIP-470%3A+TopologyTestDriver+test+input+and+output+usability+improvements

## Matching Statistics
- **Requirement Doc Coverage:** 2/2 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 9/59 files mapped (15.3%) + 50/59 files associated (84.7%) = 59/59 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | KIP-470: TopologyTestDriver test input and output usability improvements | No | N/A | knowledge |
| 2 | Status | No | N/A | process |
| 3 | Motivation | No | N/A | contextual |
| 4 | Public Interfaces | Yes | Yes | implementation |
| 5 | Proposed Changes | Yes | Yes | implementation |
| 6 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 7 | Rejected Alternatives | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `build.gradle` | build | — | Section 5 |
| 2 | `docs/streams/developer-guide/testing.html` | documentation | Section 5 | — |
| 3 | `streams/examples/src/main/java/org/apache/kafka/streams/examples/wordcount/WordCountDemo.java` | source | Section 5 | — |
| 4 | `streams/examples/src/test/java/org/apache/kafka/streams/examples/docs/DeveloperGuideTesting.java` | test | — | Section 5 |
| 5 | `streams/examples/src/test/java/org/apache/kafka/streams/examples/wordcount/WordCountDemoTest.java` | test | Section 5 | — |
| 6 | `streams/src/test/java/org/apache/kafka/streams/StreamsBuilderTest.java` | test | — | Section 5 |
| 7 | `streams/src/test/java/org/apache/kafka/streams/integration/KStreamTransformIntegrationTest.java` | test | — | Section 5 |
| 8 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/AbstractStreamTest.java` | test | — | Section 5 |
| 9 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/GlobalKTableJoinsTest.java` | test | — | Section 5 |
| 10 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KGroupedStreamImplTest.java` | test | — | Section 5 |
| 11 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KGroupedTableImplTest.java` | test | — | Section 5 |
| 12 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamBranchTest.java` | test | — | Section 5 |
| 13 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFilterTest.java` | test | — | Section 5 |
| 14 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFlatMapTest.java` | test | — | Section 5 |
| 15 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFlatMapValuesTest.java` | test | — | Section 5 |
| 16 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamForeachTest.java` | test | — | Section 5 |
| 17 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamGlobalKTableJoinTest.java` | test | — | Section 5 |
| 18 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamGlobalKTableLeftJoinTest.java` | test | — | Section 5 |
| 19 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamImplTest.java` | test | — | Section 5 |
| 20 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKStreamJoinTest.java` | test | — | Section 5 |
| 21 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKStreamLeftJoinTest.java` | test | — | Section 5 |
| 22 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKTableJoinTest.java` | test | — | Section 5 |
| 23 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKTableLeftJoinTest.java` | test | — | Section 5 |
| 24 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamMapTest.java` | test | — | Section 5 |
| 25 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamMapValuesTest.java` | test | — | Section 5 |
| 26 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamPeekTest.java` | test | — | Section 5 |
| 27 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamSelectKeyTest.java` | test | — | Section 5 |
| 28 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamTransformTest.java` | test | — | Section 5 |
| 29 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamTransformValuesTest.java` | test | — | Section 5 |
| 30 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamWindowAggregateTest.java` | test | — | Section 5 |
| 31 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableAggregateTest.java` | test | — | Section 5 |
| 32 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableFilterTest.java` | test | — | Section 5 |
| 33 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableImplTest.java` | test | — | Section 5 |
| 34 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableInnerJoinTest.java` | test | — | Section 5 |
| 35 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableLeftJoinTest.java` | test | — | Section 5 |
| 36 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableOuterJoinTest.java` | test | — | Section 5 |
| 37 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableMapKeysTest.java` | test | — | Section 5 |
| 38 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableMapValuesTest.java` | test | — | Section 5 |
| 39 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableSourceTest.java` | test | — | Section 5 |
| 40 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableTransformValuesTest.java` | test | — | Section 5 |
| 41 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/SessionWindowedKStreamImplTest.java` | test | — | Section 5 |
| 42 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/SuppressScenarioTest.java` | test | — | Section 5 |
| 43 | `streams/src/test/java/org/apache/kafka/streams/kstream/internals/TimeWindowedKStreamImplTest.java` | test | — | Section 5 |
| 44 | `streams/src/test/java/org/apache/kafka/streams/processor/internals/ProcessorTopologyTest.java` | test | — | Section 5 |
| 45 | `streams/src/test/java/org/apache/kafka/streams/state/internals/CachingWindowStoreTest.java` | test | — | Section 5 |
| 46 | `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/kstream/KStreamTest.scala` | test | — | Section 5 |
| 47 | `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/kstream/KTableTest.scala` | test | — | Section 5 |
| 48 | `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/utils/TestDriver.scala` | test | — | Section 5 |
| 49 | `streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java` | source | Section 4, Section 5 | — |
| 50 | `streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java` | source | Section 4, Section 5 | — |
| 51 | `streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java` | source | Section 4, Section 5 | — |
| 52 | `streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java` | source | Section 4, Section 5 | — |
| 53 | `streams/test-utils/src/main/java/org/apache/kafka/streams/test/OutputVerifier.java` | source | Section 4 | — |
| 54 | `streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java` | source | Section 4, Section 5 | — |
| 55 | `streams/test-utils/src/test/java/org/apache/kafka/streams/TestTopicsTest.java` | test | — | Section 5 |
| 56 | `streams/test-utils/src/test/java/org/apache/kafka/streams/TopologyTestDriverTest.java` | test | — | Section 5 |
| 57 | `streams/test-utils/src/test/java/org/apache/kafka/streams/test/ConsumerRecordFactoryTest.java` | test | — | Section 5 |
| 58 | `streams/test-utils/src/test/java/org/apache/kafka/streams/test/OutputVerifierTest.java` | test | — | Section 5 |
| 59 | `streams/test-utils/src/test/java/org/apache/kafka/streams/test/TestRecordTest.java` | test | — | Section 5 |

---

## Section 4: Public Interfaces
*Classification: Implementable*

> ```java
> package org.apache.kafka.streams;
>
> public class TopologyTestDriver {
>     public TopologyTestDriver(Topology topology, Properties config); // existing constructor
>     @Deprecate public TopologyTestDriver(Topology topology, Properties config, long initialWallClockTimeMs);
>     public TopologyTestDriver(Topology topology, Properties config, Instant initialWallClockTime);
>
>     @Deprecate public void advanceWallClockTime(long advanceMs); // can trigger wall-clock-time punctuation
>     public void advanceWallClockTime(Duration advance); // can trigger wall-clock-time punctuation
>
>     //Deprecate old pipe and read methods
>     @Deprecate public void pipeInput(ConsumerRecord<byte[], byte[]> record); // can trigger event-time punctuation
>     @Deprecate public void pipeInput(List<ConsumerRecord<byte[], byte[]>> records); // can trigger event-time punctuation
>     @Deprecate public ProducerRecord<byte[], byte[]> readOutput(String topic);
>     @Deprecate public <K, V> ProducerRecord<K, V> readOutput(String topic, Deserializer<K> keyDeserializer, Deserializer<V> valueDeserializer);
>
>     // methods for TestTopic object creation
>     public final <K, V> TestOutputTopic<K, V> createOutputTopic(final String topicName, final Serializer<K> keySerializer, final Serializer<V> valueSerializer);
>     // Uses current system time as start timestamp. Auto-advance is disabled.
>     public final <K, V> TestInputTopic<K, V> createInputTopic(final String topicName, final Deserializer<K> keyDeserializer, final Deserializer<V> valueDeserializer);
>     //Uses provided startTimestamp and autoAdvance duration for timestamp generation
>     public final <K, V> TestInputTopic<K, V> createInputTopic(final String topicName, final Deserializer<K> keyDeserializer, final Deserializer<V> valueDeserializer, final Instant startTimestamp, final Duration autoAdvance);
>
>     ...
> }
> ```
>
> ```java
> package org.apache.kafka.streams;
>
> public class TestInputTopic<K, V> {
>     //Create by TopologyTestDriver, Constructors are package private
>
>     //Timestamp handling
>     //Record timestamp can be provided when piping input or use internally tracked time configured with parameters:
>     //startTimestamp the initial timestamp for generated records, if not provided uses current system time as start timestamp.
>     //autoAdvance the time increment per generated record, if not provided auto-advance is disabled.
>
>     //Advances the internally tracked time.
>     void advanceTime(final Duration advance);
>
>     //Methods to pipe single record
>     void pipeInput(final V value);
>     void pipeInput(final K key, final V value);
>
>     // Use provided timestamp, does not auto advance internally tracked time.
>     void pipeInput(final V value, final Instant timestamp);
>     void pipeInput(final K key, final V value, final Instant timestamp);
>
>     // Method with long provided to support easier migration of old tests
>     void pipeInput(final K key, final V value, final long timestampMs);
>
>     // If record timestamp set, does not auto advance internally tracked time.
>     void pipeInput(final TestRecord<K, V> record);
>
>     //Methods to pipe list of records
>     void pipeValueList(final List<V> values);
>     void pipeKeyValueList(final List<KeyValue<K, V>> keyValues);
>
>     // Use provided timestamp, does not auto advance internally tracked time.
>     void pipeValueList(final List<V> values, final Instant startTimestamp, final Duration advanceMs);
>     void pipeKeyValueList(final List<KeyValue<K, V>> keyValues, final Instant startTimestamp, final Duration advanceMs);
>
>     // If record timestamp set, does not auto advance internally tracked time.
>     void pipeRecordList(final List<? extends TestRecord<K, V>> records);
> }
> ```
>
> ```java
> package org.apache.kafka.streams;
>
> public class TestOutputTopic<K, V> {
>     //Create by TopologyTestDriver, Constructors are package private
>
>     //Method to check queue size
>     final long getQueueSize();
>     final boolean isEmpty();
>
>     //Methods to readOutput, throw NoSuchElement if no record in queue
>     V readValue();
>     KeyValue<K, V> readKeyValue();
>     TestRecord<K, V> readRecord();
>
>     //Output as collection
>     List<V> readValuesToList();
>     List<KeyValue<K, V>> readKeyValuesToList();
>     Map<K, V> readKeyValuesToMap();
>     List<TestRecord<K, V>> readRecordsToList();
> }
> ```
>
> ```java
> package org.apache.kafka.streams.test;
> public class TestRecord<K, V> {
>     //Constructors
>     public TestRecord(final V value);
>     public TestRecord(final K key, final V value);
>     public TestRecord(final K key, final V value, final Headers headers);
>     public TestRecord(final K key, final V value, final Instant recordTime);
>     public TestRecord(final K key, final V value, final Headers headers, final Instant recordTime);
>     public TestRecord(final K key, final V value, final Headers headers, final Long timestamp);
>
>     //Constructor based on existing record
>     public TestRecord(final ConsumerRecord<K, V> record);
>     public TestRecord(final ProducerRecord<K, V> record);
>
>     // Methods like in ProducerRecord / ConsumerRecord
>     public Headers headers();
>     public K key();
>     public V value();
>     public Long timestamp();
>
>     // Getters
>     public Headers getHeaders();
>     public K getKey();
>     public V getValue();
>     public Instant getRecordTime();
>
>     //Overrides
>     public String toString();
>     public boolean equals(Object o);
>     public int hashCode();
> }
> ```
>
> ```java
> package org.apache.kafka.streams.test;
>
> //Recommended to use normal assertion library methods
> @Deprecated
> public class OutputVerifier {
>     ...
> }
> ```
>
> ```java
> package org.apache.kafka.streams.test;
>
> //Similar functionality now in TestInputTopic
> @Deprecated
> public class ConsumerRecordFactory<K, V> {
>     ...
> }
> ```

#### Requirement Summary
This section specifies the public API surface for the new test utilities: `TopologyTestDriver` gains factory methods (`createInputTopic`, `createOutputTopic`) and deprecates direct `pipeInput`/`readOutput` methods; `TestInputTopic` provides typed input piping with timestamp control; `TestOutputTopic` provides typed output reading with queue inspection; `TestRecord` is a new value class carrying key, value, headers, and timestamp; `OutputVerifier` and `ConsumerRecordFactory` are deprecated.

**File proportion:** 6/59 files mapped (10.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java` | Added | +199 / -0 | `TestInputTopic` | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java` | Added | +181 / -0 | `TestOutputTopic` | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java` | Modified | +96 / -12 | `TopologyTestDriver` | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java` | Modified | +3 / -1 | `ConsumerRecordFactory` | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/test/OutputVerifier.java` | Modified | +3 / -1 | `OutputVerifier` | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java` | Added | +289 / -0 | `TestRecord` | — |

#### Modification Summary
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java`**: Implements the `TestInputTopic<K, V>` class as specified, with typed `pipeInput`, `pipeValueList`, `pipeKeyValueList`, `pipeRecordList`, and `advanceTime` methods, replacing the untyped `ConsumerRecordFactory` + `pipeInput` workflow.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java`**: Implements the `TestOutputTopic<K, V>` class as specified, with typed `readValue`, `readKeyValue`, `readRecord`, and collection-read methods (`readValuesToList`, `readKeyValuesToList`, `readKeyValuesToMap`, `readRecordsToList`), plus queue inspection (`getQueueSize`, `isEmpty`).
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java`**: Adds `createInputTopic` and `createOutputTopic` factory methods as specified, adds `Instant`-based constructor and `Duration`-based `advanceWallClockTime`, and deprecates the old `long`-based constructor and direct `pipeInput`/`readOutput` methods.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java`**: Marks the class `@Deprecated` as specified.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/test/OutputVerifier.java`**: Marks the class `@Deprecated` as specified.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java`**: Implements the `TestRecord<K, V>` value class as specified, with all constructors (value-only, key+value, headers, timestamp, from ConsumerRecord/ProducerRecord), accessors, and `equals`/`hashCode`/`toString` overrides.

---

## Section 5: Proposed Changes
*Classification: Implementable*

> This improvement adds TestInputTopic class which replaces TopologyTestDriver and ConsumerRecordFactory methods as one class to be used to write to Input Topics and TestOutputTopic class which collects TopologyTestDriver reading methods and provide typesafe read methods.
>
> ```java
> public class SimpleTopicTest {
>
>   private TopologyTestDriver testDriver;
>   private TestInputTopic<String, String> inputTopic;
>   private TestOutputTopic<String, String> outputTopic;
>
>   @Before
>   public void setup() {
>     testDriver = new TopologyTestDriver(TestStream.getTopology(), TestStream.getConfig());
>     inputTopic = testDriver.createInputTopic(TestStream.INPUT_TOPIC, new StringDeserializer(), new StringDeserializer());
>     outputTopic = testDriver.createOutputTopic(TestStream.OUTPUT_TOPIC, new StringSerializer(), new LongSerializer());
>   }
>
>   @After
>   public void tearDown() {
>       testDriver.close();
>   }
>
>   @Test
>   public void testOneWord() {
>     //Feed word "Hello" to inputTopic and no kafka key, timestamp is irrelevant in this case
>     inputTopic.pipeInput("Hello");
>     assertThat(outputTopic.readValue()).isEqualTo("Hello");
>     //No more output in topic
>     assertThat(outputTopic.isEmpty()).isTrue();
>   }
> }
> ```
>
>   * New Example utilizing new classes test added to streams/examples/src/test/java/org/apache/kafka/streams/examples/wordcount/WordCountDemoTest.java
>
>   * Examples in Testing Kafka Streams <https://kafka.apache.org/22/documentation/streams/developer-guide/testing.html> updated to use new TopolocyTestDriver, TestInputTopic and TestOutputTopic

#### Requirement Summary
Adds a new `WordCountDemoTest` example utilizing `TestInputTopic` and `TestOutputTopic` classes. Refactors `WordCountDemo` to extract topology creation and config into static methods for testability. Updates the Kafka Streams testing developer guide documentation to demonstrate the new `TestInputTopic`/`TestOutputTopic` API.

**File proportion:** 8/59 files mapped (13.6%) + 50/59 files associated (84.7%) = 58/59 accounted (98.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `docs/streams/developer-guide/testing.html` | Modified | +47 / -48 | — | — |
| `streams/examples/src/test/java/org/apache/kafka/streams/examples/wordcount/WordCountDemoTest.java` | Added | +112 / -0 | — | — |
| `streams/examples/src/main/java/org/apache/kafka/streams/examples/wordcount/WordCountDemo.java` | Modified | +15 / -5 | `WordCountDemo` | `WordCountDemo.main`, `WordCountDemo.getStreamsConfig`, `WordCountDemo.createWordCountStream` |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java` | Added | +256 / -0 | — | `TestInputTopic.TestInputTopic`, `TestInputTopic.advanceTime`, `TestInputTopic.getTimestampAndAdvanced`, `TestInputTopic.pipeInput`, `TestInputTopic.pipeRecordList`, `TestInputTopic.pipeKeyValueList`, `TestInputTopic.pipeValueList`, `TestInputTopic.toString` |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java` | Added | +198 / -0 | — | `TestOutputTopic.TestOutputTopic`, `TestOutputTopic.readValue`, `TestOutputTopic.readKeyValue`, `TestOutputTopic.readRecord`, `TestOutputTopic.readRecordsToList`, `TestOutputTopic.readKeyValuesToMap`, `TestOutputTopic.readKeyValuesToList`, `TestOutputTopic.readValuesToList`, `TestOutputTopic.getQueueSize`, `TestOutputTopic.isEmpty`, `TestOutputTopic.toString` |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java` | Modified | +243 / -63 | — | `TopologyTestDriver.TopologyTestDriver`, `TopologyTestDriver.pipeInput`, `TopologyTestDriver.pipeRecord`, `TopologyTestDriver.captureOutputRecords`, `TopologyTestDriver.advanceWallClockTime`, `TopologyTestDriver.readOutput`, `TopologyTestDriver.getRecordsQueue`, `TopologyTestDriver.createInputTopic`, `TopologyTestDriver.createOutputTopic`, `TopologyTestDriver.readRecord`, `TopologyTestDriver.getQueueSize`, `TopologyTestDriver.isEmpty` |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java` | Modified | +4 / -0 | — | — |
| `streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java` | Added | +250 / -0 | — | `TestRecord.TestRecord`, `TestRecord.headers`, `TestRecord.key`, `TestRecord.value`, `TestRecord.timestamp`, `TestRecord.getHeaders`, `TestRecord.getKey`, `TestRecord.getValue`, `TestRecord.getRecordTime`, `TestRecord.toString`, `TestRecord.equals`, `TestRecord.hashCode` |

#### Modification Summary
- **`streams/examples/src/main/java/org/apache/kafka/streams/examples/wordcount/WordCountDemo.java`**: Extracts `getTopology()` and `getStreamsConfig()` as `static` package-private methods so that `WordCountDemoTest` can call them directly, enabling testability without running the full application.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TestInputTopic.java`**: Adds the new `TestInputTopic<K, V>` class wrapping `TopologyTestDriver` with typed `pipeInput()` methods that accept key/value pairs, `TestRecord` instances, or lists, replacing the need to manually create `ConsumerRecord` via `ConsumerRecordFactory`.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TestOutputTopic.java`**: Adds the new `TestOutputTopic<K, V>` class wrapping `TopologyTestDriver` with typed `readRecord()`, `readKeyValue()`, `readValue()`, `readKeyValuesToList()`, and `readKeyValuesToMap()` methods, replacing raw `ProducerRecord` reads and `OutputVerifier` assertions.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/TopologyTestDriver.java`**: Adds `createInputTopic()` and `createOutputTopic()` factory methods returning `TestInputTopic`/`TestOutputTopic` instances. Adds internal `piping` and `reading` methods used by the new topic classes. Deprecates the old `pipeInput(ConsumerRecord)` and `readOutput(String)` methods.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/test/ConsumerRecordFactory.java`**: Adds `@Deprecated` annotation to the entire class, directing users to use `TestInputTopic` instead.
- **`streams/test-utils/src/main/java/org/apache/kafka/streams/test/TestRecord.java`**: Adds the new `TestRecord<K, V>` value class holding key, value, headers, and timestamp, used as the common record type for `TestInputTopic` and `TestOutputTopic`.
- **`docs/streams/developer-guide/testing.html`**: Updates the Kafka Streams testing developer guide to demonstrate the new `TestInputTopic`/`TestOutputTopic` API, as the section explicitly requests (`Examples in Testing Kafka Streams ... updated to use new TopolocyTestDriver, TestInputTopic and TestOutputTopic`).
- **`streams/examples/src/test/java/org/apache/kafka/streams/examples/wordcount/WordCountDemoTest.java`**: Adds the new WordCount example test using `TestInputTopic`/`TestOutputTopic`, as the section explicitly requests (`New Example utilizing new classes test added to .../WordCountDemoTest.java`).

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `build.gradle` | Modified | +1 / -0 | Build configuration adding hamcrest test dependency | — | — |
| `streams/examples/src/test/java/org/apache/kafka/streams/examples/docs/DeveloperGuideTesting.java` | Added | +187 / -0 | Test example demonstrating the new API for the developer guide | — | — |
| `streams/src/test/java/org/apache/kafka/streams/StreamsBuilderTest.java` | Modified | +24 / -26 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/integration/KStreamTransformIntegrationTest.java` | Modified | +5 / -5 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/AbstractStreamTest.java` | Modified | +3 / -3 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/GlobalKTableJoinsTest.java` | Modified | +8 / -7 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KGroupedStreamImplTest.java` | Modified | +48 / -40 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KGroupedTableImplTest.java` | Modified | +16 / -16 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamBranchTest.java` | Modified | +3 / -3 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFilterTest.java` | Modified | +5 / -4 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFlatMapTest.java` | Modified | +6 / -4 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamFlatMapValuesTest.java` | Modified | +11 / -7 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamForeachTest.java` | Modified | +3 / -3 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamGlobalKTableJoinTest.java` | Modified | +12 / -10 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamGlobalKTableLeftJoinTest.java` | Modified | +12 / -10 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamImplTest.java` | Modified | +70 / -30 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKStreamJoinTest.java` | Modified | +91 / -70 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKStreamLeftJoinTest.java` | Modified | +36 / -21 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKTableJoinTest.java` | Modified | +13 / -10 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamKTableLeftJoinTest.java` | Modified | +11 / -8 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamMapTest.java` | Modified | +6 / -4 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamMapValuesTest.java` | Modified | +7 / -5 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamPeekTest.java` | Modified | +3 / -3 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamSelectKeyTest.java` | Modified | +6 / -4 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamTransformTest.java` | Modified | +14 / -13 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamTransformValuesTest.java` | Modified | +7 / -5 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KStreamWindowAggregateTest.java` | Modified | +87 / -74 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableAggregateTest.java` | Modified | +43 / -40 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableFilterTest.java` | Modified | +48 / -38 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableImplTest.java` | Modified | +9 / -9 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableInnerJoinTest.java` | Modified | +91 / -79 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableLeftJoinTest.java` | Modified | +102 / -90 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableKTableOuterJoinTest.java` | Modified | +98 / -87 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableMapKeysTest.java` | Modified | +4 / -4 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableMapValuesTest.java` | Modified | +36 / -28 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableSourceTest.java` | Modified | +44 / -36 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/KTableTransformValuesTest.java` | Modified | +21 / -17 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/SessionWindowedKStreamImplTest.java` | Modified | +8 / -8 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/SuppressScenarioTest.java` | Modified | +96 / -101 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/kstream/internals/TimeWindowedKStreamImplTest.java` | Modified | +8 / -8 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/processor/internals/ProcessorTopologyTest.java` | Modified | +182 / -157 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/src/test/java/org/apache/kafka/streams/state/internals/CachingWindowStoreTest.java` | Modified | +17 / -14 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/kstream/KStreamTest.scala` | Modified | +43 / -30 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/kstream/KTableTest.scala` | Modified | +97 / -79 | Test file migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/streams-scala/src/test/scala/org/apache/kafka/streams/scala/utils/TestDriver.scala` | Modified | +8 / -15 | Test utility migrated to use new TestInputTopic/TestOutputTopic API | — | — |
| `streams/test-utils/src/test/java/org/apache/kafka/streams/TestTopicsTest.java` | Added | +412 / -0 | Test file for new TestInputTopic/TestOutputTopic classes | — | — |
| `streams/test-utils/src/test/java/org/apache/kafka/streams/TopologyTestDriverTest.java` | Modified | +234 / -104 | Test file updated for new TopologyTestDriver factory methods | — | — |
| `streams/test-utils/src/test/java/org/apache/kafka/streams/test/ConsumerRecordFactoryTest.java` | Modified | +1 / -0 | Test file updated for deprecated ConsumerRecordFactory | — | — |
| `streams/test-utils/src/test/java/org/apache/kafka/streams/test/OutputVerifierTest.java` | Modified | +1 / -0 | Test file updated for deprecated OutputVerifier | — | — |
| `streams/test-utils/src/test/java/org/apache/kafka/streams/test/TestRecordTest.java` | Added | +168 / -0 | Test file for new TestRecord class | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

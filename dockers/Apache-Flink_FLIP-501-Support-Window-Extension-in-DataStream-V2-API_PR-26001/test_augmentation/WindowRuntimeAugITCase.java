/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.flink.test.streaming.api.datastream.extension.window;

import org.apache.flink.api.common.functions.AggregateFunction;
import org.apache.flink.api.common.state.AggregatingStateDeclaration;
import org.apache.flink.api.common.state.ListStateDeclaration;
import org.apache.flink.api.common.state.MapStateDeclaration;
import org.apache.flink.api.common.state.ReducingStateDeclaration;
import org.apache.flink.api.common.state.StateDeclaration;
import org.apache.flink.api.common.state.StateDeclarations;
import org.apache.flink.api.common.state.ValueStateDeclaration;
import org.apache.flink.api.common.state.v2.AggregatingState;
import org.apache.flink.api.common.state.v2.ListState;
import org.apache.flink.api.common.state.v2.MapState;
import org.apache.flink.api.common.state.v2.ReducingState;
import org.apache.flink.api.common.state.v2.ValueState;
import org.apache.flink.api.common.typeinfo.TypeDescriptors;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.connector.dsv2.WrappedSink;
import org.apache.flink.api.connector.dsv2.WrappedSource;
import org.apache.flink.connector.datagen.source.DataGeneratorSource;
import org.apache.flink.connector.datagen.source.GeneratorFunction;
import org.apache.flink.datastream.api.ExecutionEnvironment;
import org.apache.flink.datastream.api.builtin.BuiltinFuncs;
import org.apache.flink.datastream.api.common.Collector;
import org.apache.flink.datastream.api.context.PartitionedContext;
import org.apache.flink.datastream.api.context.TwoOutputPartitionedContext;
import org.apache.flink.datastream.api.extension.eventtime.EventTimeExtension;
import org.apache.flink.datastream.api.extension.window.context.OneInputWindowContext;
import org.apache.flink.datastream.api.extension.window.context.TwoInputWindowContext;
import org.apache.flink.datastream.api.extension.window.function.OneInputWindowStreamProcessFunction;
import org.apache.flink.datastream.api.extension.window.function.TwoInputNonBroadcastWindowStreamProcessFunction;
import org.apache.flink.datastream.api.extension.window.function.TwoOutputWindowStreamProcessFunction;
import org.apache.flink.datastream.api.extension.window.strategy.WindowStrategy;
import org.apache.flink.datastream.api.function.OneInputStreamProcessFunction;
import org.apache.flink.datastream.api.function.TwoInputNonBroadcastStreamProcessFunction;
import org.apache.flink.datastream.api.function.TwoOutputStreamProcessFunction;
import org.apache.flink.datastream.api.stream.GlobalStream;
import org.apache.flink.datastream.api.stream.KeyedPartitionStream;
import org.apache.flink.datastream.api.stream.NonKeyedPartitionStream;
import org.apache.flink.streaming.api.functions.sink.v2.DiscardingSink;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.Serializable;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Runtime probes for FLIP-501 window contexts, state access, and stream routing. */
class WindowRuntimeAugITCase implements Serializable {

    private transient ExecutionEnvironment env;

    @BeforeEach
    void before() throws Exception {
        env = ExecutionEnvironment.getInstance();
    }

    @AfterEach
    void after() {
        CollectingProcessFunction.reset();
    }

    @Test
    void testOneInputTumblingContextBoundsAndRecords() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("one-input-bounds", 0, 1000, 2000, 3000, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                assertThat(windowContext.getStartTime()).isEqualTo(0L);
                                assertThat(windowContext.getEndTime()).isEqualTo(5000L);
                                assertThat(count(windowContext.getAllRecords())).isEqualTo(5);
                                output.collect(new ValueWithTimestamp(5000L, -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testOneInputTumblingContextBoundsAndRecords");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(5000L);
    }

    @Test
    void testTwoInputTumblingContextBoundsAndBothRecordSides() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> left =
                getSource("two-input-left", 0, 1000, 2000, 3000, 4000);
        NonKeyedPartitionStream<ValueWithTimestamp> right =
                getSource("two-input-right", 0, 1000, 2000, 3000, 4000);

        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                windowFunction =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(Duration.ofSeconds(5)),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        assertThat(windowContext.getStartTime()).isEqualTo(0L);
                                        assertThat(windowContext.getEndTime()).isEqualTo(5000L);
                                        assertThat(count(windowContext.getAllRecords1()))
                                                .isEqualTo(5);
                                        assertThat(count(windowContext.getAllRecords2()))
                                                .isEqualTo(5);
                                        output.collect(new ValueWithTimestamp(10L, -1L));
                                    }
                                });

        left.keyBy(value -> 0)
                .connectAndProcess(right.keyBy(value -> 0), windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testTwoInputTumblingContextBoundsAndBothRecordSides");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(10L);
    }

    @Test
    void testSessionWindowMergesRecordsWithinGap() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("session-merge", 0, 3000, 6000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.session(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                assertThat(count(windowContext.getAllRecords())).isEqualTo(3);
                                output.collect(new ValueWithTimestamp(3L, -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testSessionWindowMergesRecordsWithinGap");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(3L);
    }

    @Test
    void testDeclaredWindowStateIsScopedAndReadable() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("declared-state", 0, 1000, 2000, 3000, 4000);
        ValueStateDeclaration<Long> sumState =
                StateDeclarations.valueState("aug-sum", TypeDescriptors.LONG);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public Set<org.apache.flink.api.common.state.StateDeclaration>
                                    useWindowStates() {
                                return Set.of(sumState);
                            }

                            @Override
                            public void onRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                Optional<ValueState<Long>> state =
                                        windowContext.getWindowState(sumState);
                                Long previous = state.get().value();
                                state.get()
                                        .update(
                                                (previous == null ? 0L : previous)
                                                        + record.getValue());
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                output.collect(
                                        new ValueWithTimestamp(
                                                windowContext
                                                        .getWindowState(sumState)
                                                        .get()
                                                        .value(),
                                                -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testDeclaredWindowStateIsScopedAndReadable");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(10L);
    }

    @Test
    void testUndeclaredWindowStateAccessFailsAtExecution() {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("undeclared-state", 0, 1000);
        ValueStateDeclaration<Long> undeclaredState =
                StateDeclarations.valueState("aug-undeclared", TypeDescriptors.LONG);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                windowContext.getWindowState(undeclaredState).get().update(1L);
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext) {}
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        assertThatThrownBy(() -> env.execute("testUndeclaredWindowStateAccessFailsAtExecution"))
                .hasRootCauseInstanceOf(java.util.NoSuchElementException.class);
    }

    @Test
    void testNonKeyedTimeWindowIsRejected() {
        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext) {}
                        });

        assertThatThrownBy(
                        () ->
                                getSource("non-keyed-rejected", 0, 1000)
                                        .process(windowFunction))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Only the Global Window");
    }

    @Test
    void testTwoOutputWindowRoutesBothOutputs() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("two-output-route", 0, 1000, 2000, 3000, 4000);

        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                windowFunction =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(Duration.ofSeconds(5)),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords()))
                                                .isEqualTo(5);
                                        output1.collect(new ValueWithTimestamp(1L, -1L));
                                        output2.collect(new ValueWithTimestamp(2L, -1L));
                                    }
                                });

        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                twoOutput = source.keyBy(value -> 0).process(windowFunction);

        twoOutput
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoOutput
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testTwoOutputWindowRoutesBothOutputs");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(2);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(3L);
    }

    @Test
    void testRegularKeyedProcessRoutesRemainAvailableNextToWindowRouting() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("regular-keyed-route", 0, 1000, 2000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> addTen =
                new OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp>() {
                    @Override
                    public void processRecord(
                            ValueWithTimestamp record,
                            Collector<ValueWithTimestamp> output,
                            PartitionedContext<ValueWithTimestamp> ctx) {
                        output.collect(
                                new ValueWithTimestamp(
                                        record.getValue() + 10L, record.getTimestamp()));
                    }
                };
        source.keyBy(value -> value.getValue() % 2)
                .process(addTen)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> addTwenty =
                new OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp>() {
                    @Override
                    public void processRecord(
                            ValueWithTimestamp record,
                            Collector<ValueWithTimestamp> output,
                            PartitionedContext<ValueWithTimestamp> ctx) {
                        output.collect(
                                new ValueWithTimestamp(
                                        record.getValue() + 20L, record.getTimestamp()));
                    }
                };
        source.keyBy(value -> value.getValue() % 2)
                .process(addTwenty, value -> (value.getValue() - 20L) % 2)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        TwoOutputStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                keyedTwoOutput =
                        new TwoOutputStreamProcessFunction<
                                ValueWithTimestamp,
                                ValueWithTimestamp,
                                ValueWithTimestamp>() {
                            @Override
                            public void processRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output1,
                                    Collector<ValueWithTimestamp> output2,
                                    TwoOutputPartitionedContext<
                                                    ValueWithTimestamp, ValueWithTimestamp>
                                            ctx) {
                                output1.collect(
                                        new ValueWithTimestamp(
                                                record.getValue() + 100L,
                                                record.getTimestamp()));
                                output2.collect(
                                        new ValueWithTimestamp(
                                                record.getValue() + 1000L,
                                                record.getTimestamp()));
                            }
                        };
        KeyedPartitionStream.ProcessConfigurableAndTwoKeyedPartitionStreams<
                        Long, ValueWithTimestamp, ValueWithTimestamp>
                twoKeyedStreams =
                        source.keyBy(value -> value.getValue() % 2)
                                .process(
                                        keyedTwoOutput,
                                        value -> (value.getValue() - 100L) % 2,
                                        value -> (value.getValue() - 1000L) % 2);
        twoKeyedStreams
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoKeyedStreams
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        TwoOutputStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                nonKeyedTwoOutput =
                        new TwoOutputStreamProcessFunction<
                                ValueWithTimestamp,
                                ValueWithTimestamp,
                                ValueWithTimestamp>() {
                            @Override
                            public void processRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output1,
                                    Collector<ValueWithTimestamp> output2,
                                    TwoOutputPartitionedContext<
                                                    ValueWithTimestamp, ValueWithTimestamp>
                                            ctx) {
                                output1.collect(
                                        new ValueWithTimestamp(
                                                record.getValue() + 200L,
                                                record.getTimestamp()));
                                output2.collect(
                                        new ValueWithTimestamp(
                                                record.getValue() + 2000L,
                                                record.getTimestamp()));
                            }
                        };
        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                twoNonKeyedStreams =
                        source.keyBy(value -> value.getValue() % 2).process(nonKeyedTwoOutput);
        twoNonKeyedStreams
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoNonKeyedStreams
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testRegularKeyedProcessRoutesRemainAvailableNextToWindowRouting");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(18);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(10008L);
    }

    @Test
    void testGlobalStreamTumblingWindowUsesSingleKeyRoute() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("global-one-input", 0, 1000, 2000, 3000, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                assertThat(count(windowContext.getAllRecords())).isEqualTo(5);
                                output.collect(new ValueWithTimestamp(5L, -1L));
                            }
                        });

        source.global()
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testGlobalStreamTumblingWindowUsesSingleKeyRoute");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(5L);
    }

    @Test
    void testGlobalStreamTwoInputAndTwoOutputWindowRoutes() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> left =
                getSource("global-two-input-left", 0, 1000, 2000, 3000, 4000);
        NonKeyedPartitionStream<ValueWithTimestamp> right =
                getSource("global-two-input-right", 0, 1000, 2000, 3000, 4000);

        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoInputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.global(),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords1()))
                                                .isEqualTo(5);
                                        assertThat(count(windowContext.getAllRecords2()))
                                                .isEqualTo(5);
                                        output.collect(new ValueWithTimestamp(7L, -1L));
                                    }
                                });

        left.global()
                .connectAndProcess(right.global(), twoInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("global-two-output", 0, 1000, 2000, 3000, 4000);
        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoOutputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(Duration.ofSeconds(5)),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords()))
                                                .isEqualTo(5);
                                        output1.collect(new ValueWithTimestamp(11L, -1L));
                                        output2.collect(new ValueWithTimestamp(13L, -1L));
                                    }
                                });

        GlobalStream.TwoGlobalStreams<ValueWithTimestamp, ValueWithTimestamp> outputs =
                source.global().process(twoOutputWindow);
        outputs.getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        outputs.getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testGlobalStreamTwoInputAndTwoOutputWindowRoutes");

        assertThat(CollectingProcessFunction.elementCount).isGreaterThanOrEqualTo(2);
        assertThat(CollectingProcessFunction.elementSum).isGreaterThanOrEqualTo(24L);
    }

    @Test
    void testNonKeyedGlobalWindowRoutesWithoutKeyBy() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("non-keyed-global-one-input", 0, 1000, 2000, 3000, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> oneInputWindow =
                BuiltinFuncs.window(
                        WindowStrategy.global(),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                assertThat(count(windowContext.getAllRecords())).isEqualTo(5);
                                output.collect(new ValueWithTimestamp(17L, -1L));
                            }
                        });
        source.process(oneInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        NonKeyedPartitionStream<ValueWithTimestamp> outputSource =
                getSource("non-keyed-global-two-output", 0, 1000, 2000, 3000, 4000);
        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoOutputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.global(),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords()))
                                                .isEqualTo(5);
                                        output1.collect(new ValueWithTimestamp(19L, -1L));
                                        output2.collect(new ValueWithTimestamp(23L, -1L));
                                    }
                                });
        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                twoOutputs = outputSource.process(twoOutputWindow);
        twoOutputs
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoOutputs
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        NonKeyedPartitionStream<ValueWithTimestamp> left =
                getSource("non-keyed-global-two-input-left", 0, 1000, 2000, 3000, 4000);
        NonKeyedPartitionStream<ValueWithTimestamp> right =
                getSource("non-keyed-global-two-input-right", 0, 1000, 2000, 3000, 4000);
        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoInputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.global(),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onRecord1(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        windowContext.putRecord1(record);
                                        output.collect(new ValueWithTimestamp(29L, -1L));
                                    }

                                    @Override
                                    public void onRecord2(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        windowContext.putRecord2(record);
                                        output.collect(new ValueWithTimestamp(31L, -1L));
                                    }

                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords1()))
                                                .isEqualTo(5);
                                        assertThat(count(windowContext.getAllRecords2()))
                                                .isEqualTo(5);
                                        output.collect(new ValueWithTimestamp(29L, -1L));
                                    }
                                });
        left.connectAndProcess(right, twoInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testNonKeyedGlobalWindowRoutesWithoutKeyBy");

        assertThat(CollectingProcessFunction.elementCount).isGreaterThanOrEqualTo(13);
        assertThat(CollectingProcessFunction.elementSum).isGreaterThanOrEqualTo(359L);
    }

    @Test
    void testTwoInputSessionWindowMergesBothRecordSides() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> left =
                getSource("two-input-session-left", 0, 3000, 6000);
        NonKeyedPartitionStream<ValueWithTimestamp> right =
                getSource("two-input-session-right", 0, 3000, 6000);

        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                windowFunction =
                        BuiltinFuncs.window(
                                WindowStrategy.session(Duration.ofSeconds(5)),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords1()))
                                                .isEqualTo(3);
                                        assertThat(count(windowContext.getAllRecords2()))
                                                .isEqualTo(3);
                                        output.collect(new ValueWithTimestamp(67L, -1L));
                                    }
                                });

        left.keyBy(value -> 0)
                .connectAndProcess(right.keyBy(value -> 0), windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testTwoInputSessionWindowMergesBothRecordSides");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(67L);
    }

    @Test
    void testTwoOutputSessionWindowMergesAndRoutesBothOutputs() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("two-output-session", 0, 3000, 6000);

        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                windowFunction =
                        BuiltinFuncs.window(
                                WindowStrategy.session(Duration.ofSeconds(5)),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords()))
                                                .isEqualTo(3);
                                        output1.collect(new ValueWithTimestamp(71L, -1L));
                                        output2.collect(new ValueWithTimestamp(73L, -1L));
                                    }
                                });

        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                twoOutput = source.keyBy(value -> 0).process(windowFunction);
        twoOutput
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoOutput
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testTwoOutputSessionWindowMergesAndRoutesBothOutputs");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(2);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(144L);
    }

    @Test
    void testProcessingTimeWindowsTriggerAllFunctionShapes() throws Exception {
        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> oneInputWindow =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(
                                Duration.ofMillis(5), WindowStrategy.PROCESSING_TIME),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                windowContext.putRecord(record);
                                output.collect(new ValueWithTimestamp(79L, -1L));
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                assertThat(count(windowContext.getAllRecords())).isGreaterThan(0);
                                output.collect(new ValueWithTimestamp(79L, -1L));
                            }
                        });
        getProcessingSource("processing-one-input", 8, 3)
                .keyBy(value -> 0)
                .process(oneInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoInputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(
                                        Duration.ofMillis(5), WindowStrategy.PROCESSING_TIME),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onRecord1(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        windowContext.putRecord1(record);
                                        output.collect(new ValueWithTimestamp(83L, -1L));
                                    }

                                    @Override
                                    public void onRecord2(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        windowContext.putRecord2(record);
                                        output.collect(new ValueWithTimestamp(87L, -1L));
                                    }

                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext) {
                                        output.collect(new ValueWithTimestamp(83L, -1L));
                                    }
                                });
        getProcessingSource("processing-two-input-left", 8, 3)
                .keyBy(value -> 0)
                .connectAndProcess(
                        getProcessingSource("processing-two-input-right", 8, 3)
                                .keyBy(value -> 0),
                        twoInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoOutputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(
                                        Duration.ofMillis(5), WindowStrategy.PROCESSING_TIME),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onRecord(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        windowContext.putRecord(record);
                                        output1.collect(new ValueWithTimestamp(89L, -1L));
                                        output2.collect(new ValueWithTimestamp(97L, -1L));
                                    }

                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        assertThat(count(windowContext.getAllRecords()))
                                                .isGreaterThan(0);
                                        output1.collect(new ValueWithTimestamp(89L, -1L));
                                        output2.collect(new ValueWithTimestamp(97L, -1L));
                                    }
                                });
        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                twoOutput =
                        getProcessingSource("processing-two-output", 8, 3)
                                .keyBy(value -> 0)
                                .process(twoOutputWindow);
        twoOutput
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        twoOutput
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testProcessingTimeWindowsTriggerAllFunctionShapes");

        assertThat(CollectingProcessFunction.elementCount).isGreaterThanOrEqualTo(30);
        assertThat(CollectingProcessFunction.elementSum).isGreaterThan(0L);
    }

    @Test
    void testAllDeclaredWindowStateTypesAreScopedToTheWindow() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("all-window-state-types", 0, 1000, 2000, 3000, 4000);
        ListStateDeclaration<Long> listState =
                StateDeclarations.listState("aug-list", TypeDescriptors.LONG);
        MapStateDeclaration<String, Long> mapState =
                StateDeclarations.mapState(
                        "aug-map", TypeDescriptors.STRING, TypeDescriptors.LONG);
        ReducingStateDeclaration<Long> reducingState =
                StateDeclarations.reducingState(
                        "aug-reducing", TypeDescriptors.LONG, Long::sum);
        AggregatingStateDeclaration<Long, Long, Long> aggregatingState =
                StateDeclarations.aggregatingState(
                        "aug-aggregating",
                        TypeDescriptors.LONG,
                        new AggregateFunction<Long, Long, Long>() {
                            @Override
                            public Long createAccumulator() {
                                return 0L;
                            }

                            @Override
                            public Long add(Long value, Long accumulator) {
                                return accumulator + value;
                            }

                            @Override
                            public Long getResult(Long accumulator) {
                                return accumulator;
                            }

                            @Override
                            public Long merge(Long a, Long b) {
                                return a + b;
                            }
                        });

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public Set<StateDeclaration> useWindowStates() {
                                return Set.of(
                                        listState, mapState, reducingState, aggregatingState);
                            }

                            @Override
                            public void onRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                windowContext.getWindowState(listState).get().add(record.value);
                                windowContext.getWindowState(mapState).get().put("last", record.value);
                                windowContext.getWindowState(reducingState).get().add(record.value);
                                windowContext.getWindowState(aggregatingState).get().add(record.value);
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                ListState<Long> list = windowContext.getWindowState(listState).get();
                                MapState<String, Long> map =
                                        windowContext.getWindowState(mapState).get();
                                ReducingState<Long> reduced =
                                        windowContext.getWindowState(reducingState).get();
                                AggregatingState<Long, Long> aggregated =
                                        windowContext.getWindowState(aggregatingState).get();
                                assertThat(list.get()).containsExactly(0L, 1L, 2L, 3L, 4L);
                                assertThat(map.get("last")).isEqualTo(4L);
                                assertThat(map.contains("last")).isTrue();
                                assertThat(map.isEmpty()).isFalse();
                                assertThat(reduced.get()).isEqualTo(10L);
                                assertThat(aggregated.get()).isEqualTo(10L);
                                output.collect(new ValueWithTimestamp(reduced.get(), -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testAllDeclaredWindowStateTypesAreScopedToTheWindow");

        assertThat(CollectingProcessFunction.elementCount).isEqualTo(1);
        assertThat(CollectingProcessFunction.elementSum).isEqualTo(10L);
    }

    @Test
    void testRedistributableWindowStateIsRejectedAtExecution() {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("redistributable-window-state", 0, 1000);
        ListStateDeclaration<Long> redistributableState =
                StateDeclarations.listStateBuilder("aug-redistributable", TypeDescriptors.LONG)
                        .redistributeBy(ListStateDeclaration.RedistributionStrategy.UNION)
                        .build();

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public Set<StateDeclaration> useWindowStates() {
                                return Set.of(redistributableState);
                            }

                            @Override
                            public void onRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                windowContext.getWindowState(redistributableState);
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext) {}
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        assertThatThrownBy(() -> env.execute("testRedistributableWindowStateIsRejectedAtExecution"))
                .hasRootCauseInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void testSessionWindowRejectsWindowStateAccess() {
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("session-window-state-rejected", 0, 1000, 2000);
        ValueStateDeclaration<Long> sessionState =
                StateDeclarations.valueState("aug-session-state", TypeDescriptors.LONG);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.session(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public Set<StateDeclaration> useWindowStates() {
                                return Set.of(sessionState);
                            }

                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                windowContext.getWindowState(sessionState);
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        assertThatThrownBy(() -> env.execute("testSessionWindowRejectsWindowStateAccess"))
                .hasRootCauseInstanceOf(IllegalStateException.class);
    }

    @Test
    void testLateRecordsReachOneInputAndTwoOutputCallbacks() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> oneInputSource =
                getSource("late-one-input", 10_000, 0);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> oneInputWindow =
                BuiltinFuncs.window(
                        WindowStrategy.tumbling(Duration.ofSeconds(5)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                output.collect(new ValueWithTimestamp(31L, -1L));
                            }

                            @Override
                            public void onLateRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx) {
                                output.collect(new ValueWithTimestamp(37L, -1L));
                            }
                        });

        oneInputSource
                .keyBy(value -> 0)
                .process(oneInputWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        NonKeyedPartitionStream<ValueWithTimestamp> twoOutputSource =
                getSource("late-two-output", 10_000, 0);
        TwoOutputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                twoOutputWindow =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(Duration.ofSeconds(5)),
                                new TwoOutputWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx,
                                            OneInputWindowContext<ValueWithTimestamp> windowContext)
                                            throws Exception {
                                        output1.collect(new ValueWithTimestamp(41L, -1L));
                                    }

                                    @Override
                                    public void onLateRecord(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output1,
                                            Collector<ValueWithTimestamp> output2,
                                            TwoOutputPartitionedContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    ctx) {
                                        output1.collect(new ValueWithTimestamp(43L, -1L));
                                        output2.collect(new ValueWithTimestamp(47L, -1L));
                                    }
                                });
        NonKeyedPartitionStream.ProcessConfigurableAndTwoNonKeyedPartitionStream<
                        ValueWithTimestamp, ValueWithTimestamp>
                lateOutputs = twoOutputSource.keyBy(value -> 0).process(twoOutputWindow);
        lateOutputs
                .getFirst()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));
        lateOutputs
                .getSecond()
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testLateRecordsReachOneInputAndTwoOutputCallbacks");

        assertThat(CollectingProcessFunction.elementCount).isGreaterThanOrEqualTo(4);
        assertThat(CollectingProcessFunction.elementSum).isGreaterThanOrEqualTo(158L);
    }

    @Test
    void testLateRecordsReachTwoInputCallbacks() throws Exception {
        NonKeyedPartitionStream<ValueWithTimestamp> left = getSource("late-left", 10_000, 0);
        NonKeyedPartitionStream<ValueWithTimestamp> right = getSource("late-right", 10_000, 0);

        TwoInputNonBroadcastStreamProcessFunction<
                        ValueWithTimestamp, ValueWithTimestamp, ValueWithTimestamp>
                windowFunction =
                        BuiltinFuncs.window(
                                WindowStrategy.tumbling(Duration.ofSeconds(5)),
                                new TwoInputNonBroadcastWindowStreamProcessFunction<
                                        ValueWithTimestamp,
                                        ValueWithTimestamp,
                                        ValueWithTimestamp>() {
                                    @Override
                                    public void onTrigger(
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx,
                                            TwoInputWindowContext<
                                                            ValueWithTimestamp, ValueWithTimestamp>
                                                    windowContext)
                                            throws Exception {
                                        output.collect(new ValueWithTimestamp(53L, -1L));
                                    }

                                    @Override
                                    public void onLateRecord1(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx) {
                                        output.collect(new ValueWithTimestamp(59L, -1L));
                                    }

                                    @Override
                                    public void onLateRecord2(
                                            ValueWithTimestamp record,
                                            Collector<ValueWithTimestamp> output,
                                            PartitionedContext<ValueWithTimestamp> ctx) {
                                        output.collect(new ValueWithTimestamp(61L, -1L));
                                    }
                                });

        left.keyBy(value -> 0)
                .connectAndProcess(right.keyBy(value -> 0), windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testLateRecordsReachTwoInputCallbacks");

        assertThat(CollectingProcessFunction.elementCount).isGreaterThanOrEqualTo(2);
        assertThat(CollectingProcessFunction.elementSum).isGreaterThanOrEqualTo(112L);
    }

    private static final java.util.List<Long> slidingObservedStartTimes =
            java.util.Collections.synchronizedList(new java.util.ArrayList<Long>());
    private static java.lang.Long slidingZeroStartWindowSpan;
    private static int slidingZeroStartWindowRecordCount;
    private static long slidingMinObservedWindowSpan;
    private static long slidingMaxObservedWindowSpan;

    private static void resetSlidingProbe() {
        slidingObservedStartTimes.clear();
        slidingZeroStartWindowSpan = null;
        slidingZeroStartWindowRecordCount = -1;
        slidingMinObservedWindowSpan = Long.MAX_VALUE;
        slidingMaxObservedWindowSpan = Long.MIN_VALUE;
    }

    private static long smallestGapBetweenDistinctStarts() {
        java.util.TreeSet<Long> distinct = new java.util.TreeSet<>(slidingObservedStartTimes);
        long minGap = Long.MAX_VALUE;
        java.lang.Long previous = null;
        for (Long start : distinct) {
            if (previous != null) {
                minGap = Math.min(minGap, start - previous);
            }
            previous = start;
        }
        return minGap;
    }

    @Test
    void testEventTimeSlidingWindowBoundsAndOverlap() throws Exception {
        resetSlidingProbe();
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("sliding-bounds", 0, 1000, 2000, 3000, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.sliding(Duration.ofSeconds(5), Duration.ofSeconds(1)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                long start = windowContext.getStartTime();
                                long span = windowContext.getEndTime() - start;
                                slidingObservedStartTimes.add(start);
                                slidingMinObservedWindowSpan =
                                        Math.min(slidingMinObservedWindowSpan, span);
                                slidingMaxObservedWindowSpan =
                                        Math.max(slidingMaxObservedWindowSpan, span);
                                if (start == 0L) {
                                    slidingZeroStartWindowSpan = span;
                                    slidingZeroStartWindowRecordCount =
                                            count(windowContext.getAllRecords());
                                }
                                output.collect(new ValueWithTimestamp(start, -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testEventTimeSlidingWindowBoundsAndOverlap");

        // Under event time the slide-aligned window [0, 5000) must have fired with all
        // five event-time records. With processing-time assignment the event watermarks
        // never drive these windows, so no window starting at event-time 0 is observed.
        assertThat(slidingZeroStartWindowSpan)
                .as("event-time window starting at 0 must exist and span the window size")
                .isEqualTo(5000L);
        assertThat(slidingZeroStartWindowRecordCount)
                .as("window [0, 5000) must contain all five event-time records")
                .isEqualTo(5);
        // Every emitted window spans the configured size, not the slide interval.
        assertThat(slidingMaxObservedWindowSpan).isEqualTo(5000L);
        assertThat(slidingMinObservedWindowSpan).isEqualTo(5000L);
        // Sliding windows overlap, so consecutive distinct starts are one slide apart.
        java.util.TreeSet<Long> distinctStarts =
                new java.util.TreeSet<>(slidingObservedStartTimes);
        assertThat(distinctStarts.size())
                .as("overlapping sliding windows produce many distinct start times")
                .isGreaterThan(1);
        assertThat(smallestGapBetweenDistinctStarts())
                .as("smallest gap between consecutive window starts equals the slide interval")
                .isEqualTo(1000L);
        assertThat(distinctStarts).contains(0L, 1000L);
    }

    @Test
    void testEventTimeSlidingWindowFromFourArgFactoryKeepsSlideInterval() throws Exception {
        resetSlidingProbe();
        NonKeyedPartitionStream<ValueWithTimestamp> source =
                getSource("sliding-four-arg", 0, 1000, 2000, 3000, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> windowFunction =
                BuiltinFuncs.window(
                        WindowStrategy.sliding(
                                Duration.ofSeconds(5),
                                Duration.ofSeconds(1),
                                WindowStrategy.EVENT_TIME,
                                Duration.ZERO),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                long start = windowContext.getStartTime();
                                long span = windowContext.getEndTime() - start;
                                slidingObservedStartTimes.add(start);
                                slidingMinObservedWindowSpan =
                                        Math.min(slidingMinObservedWindowSpan, span);
                                slidingMaxObservedWindowSpan =
                                        Math.max(slidingMaxObservedWindowSpan, span);
                                if (start == 0L) {
                                    slidingZeroStartWindowSpan = span;
                                    slidingZeroStartWindowRecordCount =
                                            count(windowContext.getAllRecords());
                                }
                                output.collect(new ValueWithTimestamp(start, -1L));
                            }
                        });

        source.keyBy(value -> 0)
                .process(windowFunction)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testEventTimeSlidingWindowFromFourArgFactoryKeepsSlideInterval");

        // The explicit four-argument event-time factory must preserve an independent
        // slide interval, so the [0, 5000) window fires with all five records and the
        // windows overlap with one-slide spacing.
        assertThat(slidingZeroStartWindowSpan)
                .as("event-time window starting at 0 must exist and span the window size")
                .isEqualTo(5000L);
        assertThat(slidingZeroStartWindowRecordCount)
                .as("window [0, 5000) must contain all five event-time records")
                .isEqualTo(5);
        assertThat(slidingMaxObservedWindowSpan).isEqualTo(5000L);
        assertThat(slidingMinObservedWindowSpan).isEqualTo(5000L);
        java.util.TreeSet<Long> distinctStarts =
                new java.util.TreeSet<>(slidingObservedStartTimes);
        assertThat(distinctStarts.size())
                .as("overlapping sliding windows produce many distinct start times")
                .isGreaterThan(1);
        assertThat(smallestGapBetweenDistinctStarts())
                .as("smallest gap between consecutive window starts equals the slide interval")
                .isEqualTo(1000L);
        assertThat(distinctStarts).contains(0L, 1000L);
    }

    private static long slidingDefaultLateRecordCount;
    private static long slidingExplicitLateRecordCount;
    private static long slidingExplicitTriggerCount;

    @Test
    void testEventTimeSlidingWindowDefaultLatenessIsZeroAndExplicitLatenessIsHonored()
            throws Exception {
        // ---- Job A: the two-argument default must use zero allowed lateness. The ts=4000
        // record belongs to the sliding windows up to [4000, 9000); once the ts=9500
        // watermark passes all of them the record is late for every window and is routed
        // to onLateRecord. A constructor that uses the slide interval (1s) as the default
        // lateness keeps [4000, 9000) open until watermark 10000, so the record is not
        // yet late and never reaches the late-record callback. ----
        slidingDefaultLateRecordCount = 0L;
        NonKeyedPartitionStream<ValueWithTimestamp> defaultSource =
                getSource("sliding-late-default", 9500, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> defaultWindow =
                BuiltinFuncs.window(
                        WindowStrategy.sliding(Duration.ofSeconds(5), Duration.ofSeconds(1)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                output.collect(new ValueWithTimestamp(101L, -1L));
                            }

                            @Override
                            public void onLateRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx) {
                                slidingDefaultLateRecordCount++;
                                output.collect(new ValueWithTimestamp(103L, -1L));
                            }
                        });

        defaultSource
                .keyBy(value -> 0)
                .process(defaultWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testEventTimeSlidingWindowDefaultLatenessZero");

        assertThat(slidingDefaultLateRecordCount)
                .as("two-argument sliding default uses zero allowed lateness")
                .isGreaterThanOrEqualTo(1L);

        // ---- Job B: an explicitly configured positive lateness must be honored at
        // runtime. With three seconds of allowed lateness the ts=4000 record's later
        // windows (up to [4000, 9000)) are still within lateness at watermark 9500, so the
        // record is accepted and is never late. A runtime that reads the configured
        // lateness as zero expires those windows at watermark 8999 and reports the record
        // as late instead. ----
        slidingExplicitLateRecordCount = 0L;
        slidingExplicitTriggerCount = 0L;
        NonKeyedPartitionStream<ValueWithTimestamp> explicitSource =
                getSource("sliding-late-explicit", 9500, 4000);

        OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> explicitWindow =
                BuiltinFuncs.window(
                        WindowStrategy.sliding(
                                Duration.ofSeconds(5),
                                Duration.ofSeconds(1),
                                WindowStrategy.EVENT_TIME,
                                Duration.ofSeconds(3)),
                        new OneInputWindowStreamProcessFunction<
                                ValueWithTimestamp, ValueWithTimestamp>() {
                            @Override
                            public void onTrigger(
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx,
                                    OneInputWindowContext<ValueWithTimestamp> windowContext)
                                    throws Exception {
                                slidingExplicitTriggerCount++;
                                output.collect(new ValueWithTimestamp(107L, -1L));
                            }

                            @Override
                            public void onLateRecord(
                                    ValueWithTimestamp record,
                                    Collector<ValueWithTimestamp> output,
                                    PartitionedContext<ValueWithTimestamp> ctx) {
                                slidingExplicitLateRecordCount++;
                                output.collect(new ValueWithTimestamp(109L, -1L));
                            }
                        });

        explicitSource
                .keyBy(value -> 0)
                .process(explicitWindow)
                .process(new CollectingProcessFunction())
                .withParallelism(1)
                .toSink(new WrappedSink<>(new DiscardingSink<>()));

        env.execute("testEventTimeSlidingWindowExplicitLatenessHonored");

        // The windows must actually fire (non-vacuous), and the within-lateness record
        // must not be reported late when the configured lateness is honored.
        assertThat(slidingExplicitTriggerCount)
                .as("explicit-lateness sliding job must fire windows")
                .isGreaterThan(0L);
        assertThat(slidingExplicitLateRecordCount)
                .as("explicitly configured sliding allowed lateness must be honored at runtime")
                .isEqualTo(0L);
    }

    private NonKeyedPartitionStream<ValueWithTimestamp> getSource(
            String sourceName, long... timestamps) {
        NonKeyedPartitionStream<ValueWithTimestamp> stream =
                env.fromSource(
                        new WrappedSource<>(
                                new DataGeneratorSource<>(
                                        new SequenceGenerator(timestamps),
                                        timestamps.length,
                                        TypeInformation.of(ValueWithTimestamp.class))),
                        sourceName);
        return stream.process(
                EventTimeExtension.<ValueWithTimestamp>newWatermarkGeneratorBuilder(
                                ValueWithTimestamp::getTimestamp)
                        .perEventWatermark()
                        .buildAsProcessFunction());
    }

    private NonKeyedPartitionStream<ValueWithTimestamp> getProcessingSource(
            String sourceName, int elementCount, long sleepMillis) {
        return env.fromSource(
                new WrappedSource<>(
                        new DataGeneratorSource<>(
                                new SleepingSequenceGenerator(sleepMillis),
                                elementCount,
                                TypeInformation.of(ValueWithTimestamp.class))),
                sourceName);
    }

    private static int count(Iterable<?> records) {
        int count = 0;
        for (Object ignored : records) {
            count++;
        }
        return count;
    }

    public static class ValueWithTimestamp {
        private final long value;
        private final long timestamp;

        public ValueWithTimestamp(long value, long timestamp) {
            this.value = value;
            this.timestamp = timestamp;
        }

        public long getValue() {
            return value;
        }

        public long getTimestamp() {
            return timestamp;
        }
    }

    private static class SequenceGenerator implements GeneratorFunction<Long, ValueWithTimestamp> {
        private final long[] timestamps;

        private SequenceGenerator(long[] timestamps) {
            this.timestamps = timestamps;
        }

        @Override
        public ValueWithTimestamp map(Long value) {
            int index = value.intValue();
            return new ValueWithTimestamp(index, timestamps[index]);
        }
    }

    private static class SleepingSequenceGenerator
            implements GeneratorFunction<Long, ValueWithTimestamp> {
        private final long sleepMillis;

        private SleepingSequenceGenerator(long sleepMillis) {
            this.sleepMillis = sleepMillis;
        }

        @Override
        public ValueWithTimestamp map(Long value) throws Exception {
            Thread.sleep(sleepMillis);
            return new ValueWithTimestamp(value, -1L);
        }
    }

    private static class CollectingProcessFunction
            implements OneInputStreamProcessFunction<ValueWithTimestamp, ValueWithTimestamp> {
        private static long elementSum;
        private static long elementCount;

        private static void reset() {
            elementSum = 0;
            elementCount = 0;
        }

        @Override
        public void processRecord(
                ValueWithTimestamp record,
                Collector<ValueWithTimestamp> output,
                PartitionedContext<ValueWithTimestamp> ctx) {
            elementCount++;
            elementSum += record.getValue();
        }
    }
}

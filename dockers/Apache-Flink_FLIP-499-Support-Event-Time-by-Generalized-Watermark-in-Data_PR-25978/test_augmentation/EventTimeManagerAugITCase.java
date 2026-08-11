/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.flink.test.streaming.api.datastream.extension.eventtime;

import org.apache.flink.api.connector.dsv2.DataStreamV2SourceUtils;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.datastream.api.ExecutionEnvironment;
import org.apache.flink.datastream.api.common.Collector;
import org.apache.flink.datastream.api.context.NonPartitionedContext;
import org.apache.flink.datastream.api.context.PartitionedContext;
import org.apache.flink.datastream.api.extension.eventtime.EventTimeExtension;
import org.apache.flink.datastream.api.extension.eventtime.function.OneInputEventTimeStreamProcessFunction;
import org.apache.flink.datastream.api.extension.eventtime.timer.EventTimeManager;
import org.apache.flink.datastream.api.stream.NonKeyedPartitionStream;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.Serializable;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;

import static org.assertj.core.api.Assertions.assertThat;

/** Augmented IT case for FLIP-499 EventTimeManager public behavior. */
class EventTimeManagerAugITCase implements Serializable {

    private ExecutionEnvironment env;
    private final List<Tuple2<Long, String>> inputRecords =
            List.of(Tuple2.of(1L, "a"), Tuple2.of(2L, "b"), Tuple2.of(3L, "c"));

    @BeforeEach
    void before() throws Exception {
        env = ExecutionEnvironment.getInstance();
    }

    @AfterEach
    void after() {
        CurrentTimeEventTimeProcessFunction.receivedEventTimes.clear();
        CurrentTimeEventTimeProcessFunction.currentTimes.clear();
    }

    @Test
    void testEventTimeManagerCurrentTimeTracksWatermark() throws Exception {
        NonKeyedPartitionStream<Tuple2<Long, String>> source = getSourceWithWatermarkGenerator();
        source.keyBy(x -> x.f0)
                .process(
                        EventTimeExtension.wrapProcessFunction(
                                new CurrentTimeEventTimeProcessFunction()));
        env.execute("testEventTimeManagerCurrentTimeTracksWatermark");

        assertThat(CurrentTimeEventTimeProcessFunction.receivedEventTimes)
                .containsExactly(1L, 2L, 3L);
        assertThat(CurrentTimeEventTimeProcessFunction.currentTimes).containsExactly(1L, 2L, 3L);
    }

    private NonKeyedPartitionStream<Tuple2<Long, String>> getSourceWithWatermarkGenerator() {
        NonKeyedPartitionStream<Tuple2<Long, String>> source =
                env.fromSource(DataStreamV2SourceUtils.fromData(inputRecords), "Source")
                        .withParallelism(1);

        return source.process(
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .perEventWatermark()
                        .buildAsProcessFunction());
    }

    private static class CurrentTimeEventTimeProcessFunction
            implements OneInputEventTimeStreamProcessFunction<
                    Tuple2<Long, String>, Tuple2<Long, String>> {
        private static final ConcurrentLinkedQueue<Long> receivedEventTimes =
                new ConcurrentLinkedQueue<>();
        private static final ConcurrentLinkedQueue<Long> currentTimes = new ConcurrentLinkedQueue<>();
        private EventTimeManager eventTimeManager;

        @Override
        public void initEventTimeProcessFunction(EventTimeManager eventTimeManager) {
            this.eventTimeManager = eventTimeManager;
        }

        @Override
        public void processRecord(
                Tuple2<Long, String> record,
                Collector<Tuple2<Long, String>> output,
                PartitionedContext<Tuple2<Long, String>> ctx)
                throws Exception {
            output.collect(record);
        }

        @Override
        public void onEventTimeWatermark(
                long watermarkTimestamp,
                Collector<Tuple2<Long, String>> output,
                NonPartitionedContext<Tuple2<Long, String>> ctx) {
            receivedEventTimes.add(watermarkTimestamp);
            currentTimes.add(eventTimeManager.currentTime());
        }
    }
}

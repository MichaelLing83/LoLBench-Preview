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

import org.apache.flink.api.common.watermark.BoolWatermark;
import org.apache.flink.api.common.watermark.LongWatermark;
import org.apache.flink.api.common.watermark.WatermarkDeclaration;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.datastream.api.extension.eventtime.EventTimeExtension;
import org.apache.flink.datastream.api.function.OneInputStreamProcessFunction;
import org.apache.flink.datastream.impl.operators.ProcessOperator;
import org.apache.flink.runtime.event.WatermarkEvent;
import org.apache.flink.streaming.runtime.streamrecord.StreamRecord;
import org.apache.flink.streaming.util.OneInputStreamOperatorTestHarness;
import org.apache.flink.streaming.util.watermark.WatermarkUtils;
import org.apache.flink.util.InstantiationUtil;

import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/** Augmented tests for FLIP-499 watermark generator builder behavior. */
class EventTimeGeneratorBuilderAugTest {

    @Test
    void testDefaultBuilderUsesPeriodicEventTimeWatermarks() throws Exception {
        OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>> processFunction =
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .buildAsProcessFunction();
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
                operatorTestHarness = getOperatorTestHarness(processFunction);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1000L, "a")));
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput());
        operatorTestHarness.getProcessingTimeService().advance(200);
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 1000L);

        operatorTestHarness.close();
    }

    @Test
    void testNoWatermarkModeSuppressesEventTimeWatermarks() throws Exception {
        OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>> processFunction =
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .noWatermark()
                        .buildAsProcessFunction();
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
                operatorTestHarness = getOperatorTestHarness(processFunction);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1000L, "a")));
        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(2000L, "b")));
        operatorTestHarness.getProcessingTimeService().advance(1000);
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput());

        operatorTestHarness.close();
    }

    @Test
    void testConfiguredPeriodicIntervalIsUsed() throws Exception {
        OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>> processFunction =
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .periodicWatermark(Duration.ofMillis(10))
                        .buildAsProcessFunction();
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
                operatorTestHarness = getOperatorTestHarness(processFunction);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1000L, "a")));
        operatorTestHarness.getProcessingTimeService().advance(10);
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 1000L);

        operatorTestHarness.close();
    }

    @Test
    void testBuilderIdlenessEmitsIdleAndActiveStatus() throws Exception {
        OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>> processFunction =
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .perEventWatermark()
                        .withIdleness(Duration.ofMillis(200))
                        .buildAsProcessFunction();
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
                operatorTestHarness = getOperatorTestHarness(processFunction);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1000L, "a")));
        checkOutputIdleStatusWatermarks(operatorTestHarness.getOutput());
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 1000L);

        operatorTestHarness.getProcessingTimeService().advance(200);
        operatorTestHarness.getProcessingTimeService().advance(200);
        operatorTestHarness.getProcessingTimeService().advance(200);
        operatorTestHarness.getProcessingTimeService().advance(200);
        operatorTestHarness.getProcessingTimeService().advance(200);
        checkOutputIdleStatusWatermarks(operatorTestHarness.getOutput(), true);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(2000L, "b")));
        checkOutputIdleStatusWatermarks(operatorTestHarness.getOutput(), true, false);
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 1000L, 2000L);

        operatorTestHarness.close();
    }

    @Test
    void testMaxOutOfOrderTimeIsSubtracted() throws Exception {
        OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>> processFunction =
                EventTimeExtension.<Tuple2<Long, String>>newWatermarkGeneratorBuilder(
                                event -> event.f0)
                        .perEventWatermark()
                        .withMaxOutOfOrderTime(Duration.ofMillis(100))
                        .buildAsProcessFunction();
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
                operatorTestHarness = getOperatorTestHarness(processFunction);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1000L, "a")));
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 900L);

        operatorTestHarness.processElement(new StreamRecord<>(Tuple2.of(1001L, "b")));
        checkOutputEventTimeWatermarks(operatorTestHarness.getOutput(), 900L, 901L);

        operatorTestHarness.close();
    }

    private OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>>
            getOperatorTestHarness(
                    OneInputStreamProcessFunction<Tuple2<Long, String>, Tuple2<Long, String>>
                            processFunction)
                    throws Exception {
        ProcessOperator<Tuple2<Long, String>, Tuple2<Long, String>> processOperator =
                new ProcessOperator<>(processFunction);
        OneInputStreamOperatorTestHarness<Tuple2<Long, String>, Tuple2<Long, String>> testHarness =
                new OneInputStreamOperatorTestHarness<>(processOperator);
        Set<WatermarkDeclaration> watermarkDeclarations =
                (Set<WatermarkDeclaration>) processFunction.declareWatermarks();
        byte[] serializedWatermarkDeclarations =
                InstantiationUtil.serializeObject(
                        WatermarkUtils.convertToInternalWatermarkDeclarations(
                                watermarkDeclarations));
        testHarness.getStreamConfig().setWatermarkDeclarations(serializedWatermarkDeclarations);
        testHarness.open();
        return testHarness;
    }

    private void checkOutputEventTimeWatermarks(
            ConcurrentLinkedQueue<Object> output, Long... expectedEventTimeWatermarks) {
        List<Long> actualEventTimeWatermarks =
                output.stream()
                        .filter(
                                object ->
                                        object instanceof WatermarkEvent
                                                && EventTimeExtension.isEventTimeWatermark(
                                                        ((WatermarkEvent) object).getWatermark()))
                        .map(
                                watermarkEvent ->
                                        ((LongWatermark)
                                                        ((WatermarkEvent) watermarkEvent)
                                                                .getWatermark())
                                                .getValue())
                        .collect(Collectors.toList());
        assertThat(actualEventTimeWatermarks).containsExactly(expectedEventTimeWatermarks);
    }

    private void checkOutputIdleStatusWatermarks(
            ConcurrentLinkedQueue<Object> output, Boolean... expectedIdleStatusWatermarks) {
        List<Boolean> actualEventTimeWatermarks =
                output.stream()
                        .filter(
                                object ->
                                        object instanceof WatermarkEvent
                                                && EventTimeExtension.isIdleStatusWatermark(
                                                        ((WatermarkEvent) object).getWatermark()))
                        .map(
                                watermarkEvent ->
                                        ((BoolWatermark)
                                                        ((WatermarkEvent) watermarkEvent)
                                                                .getWatermark())
                                                .getValue())
                        .collect(Collectors.toList());
        assertThat(actualEventTimeWatermarks).containsExactly(expectedIdleStatusWatermarks);
    }
}

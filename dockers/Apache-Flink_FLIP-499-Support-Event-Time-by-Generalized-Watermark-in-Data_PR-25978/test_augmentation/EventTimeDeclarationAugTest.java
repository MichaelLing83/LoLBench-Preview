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

import org.apache.flink.api.common.watermark.WatermarkCombinationFunction;
import org.apache.flink.api.common.watermark.WatermarkHandlingStrategy;
import org.apache.flink.datastream.api.extension.eventtime.EventTimeExtension;
import org.apache.flink.streaming.runtime.watermark.AbstractInternalWatermarkDeclaration;
import org.apache.flink.streaming.runtime.watermark.WatermarkCombiner;
import org.apache.flink.streaming.util.watermark.WatermarkUtils;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/** Augmented tests for FLIP-499 public watermark declarations. */
class EventTimeDeclarationAugTest {

    @Test
    void testEventTimeDeclarationUsesMinAndWaitsForAllChannels() {
        assertThat(
                        EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION
                                .getCombinationPolicy()
                                .getWatermarkCombinationFunction())
                .isEqualTo(WatermarkCombinationFunction.NumericWatermarkCombinationFunction.MIN);
        assertThat(
                        EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION
                                .getCombinationPolicy()
                                .isCombineWaitForAllChannels())
                .isTrue();
        assertThat(EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION.getDefaultHandlingStrategy())
                .isEqualTo(WatermarkHandlingStrategy.FORWARD);

        assertThat(
                        EventTimeExtension.isEventTimeWatermark(
                                EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION
                                        .newWatermark(42L)))
                .isTrue();
        assertThat(
                        EventTimeExtension.isIdleStatusWatermark(
                                EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION
                                        .newWatermark(42L)))
                .isFalse();
    }

    @Test
    void testIdleStatusDeclarationUsesAndAndWaitsForAllChannels() {
        assertThat(
                        EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                .getCombinationPolicy()
                                .getWatermarkCombinationFunction())
                .isEqualTo(WatermarkCombinationFunction.BoolWatermarkCombinationFunction.AND);
        assertThat(
                        EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                .getCombinationPolicy()
                                .isCombineWaitForAllChannels())
                .isTrue();
        assertThat(
                        EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                .getDefaultHandlingStrategy())
                .isEqualTo(WatermarkHandlingStrategy.FORWARD);

        assertThat(
                        EventTimeExtension.isIdleStatusWatermark(
                                EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                        .newWatermark(true)))
                .isTrue();
        assertThat(
                        EventTimeExtension.isEventTimeWatermark(
                                EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                        .newWatermark(true)))
                .isFalse();
    }

    @Test
    void testEventTimeDeclarationsInstallBothCombinersWithoutIdleDeclaration() {
        Set<AbstractInternalWatermarkDeclaration<?>> internalDeclarations =
                WatermarkUtils.convertToInternalWatermarkDeclarations(
                        Set.of(EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION));
        Map<String, WatermarkCombiner> watermarkCombiners = new HashMap<>();

        WatermarkUtils.addEventTimeWatermarkCombinerIfNeeded(
                internalDeclarations, watermarkCombiners, 2);

        assertThat(watermarkCombiners)
                .containsKeys(
                        EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION.getIdentifier(),
                        EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION.getIdentifier());
        assertThat(
                        watermarkCombiners.get(
                                EventTimeExtension.EVENT_TIME_WATERMARK_DECLARATION
                                        .getIdentifier()))
                .isSameAs(
                        watermarkCombiners.get(
                                EventTimeExtension.IDLE_STATUS_WATERMARK_DECLARATION
                                        .getIdentifier()));
    }
}

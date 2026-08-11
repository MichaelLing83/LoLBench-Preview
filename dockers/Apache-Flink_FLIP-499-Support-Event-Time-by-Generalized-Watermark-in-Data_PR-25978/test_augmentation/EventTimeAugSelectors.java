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

import org.junit.jupiter.api.Test;

/** Augmented selector classes for FLIP-499 event-time watermark behavior. */
class EventTimeExtensionAugITCase extends EventTimeExtensionITCase {

    @Test
    void testTwoOutputEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer()
            throws Exception {
        super.testTwoOutputEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer();
    }

    @Test
    void testTwoOutputEventTimeProcessFunctionForwardEventTimeWatermark() throws Exception {
        super.testTwoOutputEventTimeProcessFunctionForwardEventTimeWatermark();
    }

    @Test
    void testTwoInputBroadcastEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer()
            throws Exception {
        super.testTwoInputBroadcastEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer();
    }

    @Test
    void testTwoInputBroadcastEventTimeProcessFunctionForwardEventTimeWatermark() throws Exception {
        super.testTwoInputBroadcastEventTimeProcessFunctionForwardEventTimeWatermark();
    }

    @Test
    void testTwoInputNonBroadcastProcessFunctionForwardEventTimeWatermark() throws Exception {
        super.testTwoInputNonBroadcastProcessFunctionForwardEventTimeWatermark();
    }

    @Test
    void testTwoInputNonBroadcastEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer()
            throws Exception {
        super.testTwoInputNonBroadcastEventTimeProcessFunctionReceiveEventTimeWatermarkAndRegisterTimer();
    }

    @Test
    void testTwoInputNonBroadcastEventTimeProcessFunctionForwardEventTimeWatermark()
            throws Exception {
        super.testTwoInputNonBroadcastEventTimeProcessFunctionForwardEventTimeWatermark();
    }
}

class EventTimeWatermarkCombinerAugTest extends EventTimeWatermarkCombinerTest {

    @Test
    void testCombinedResultIsMin() throws Exception {
        super.testCombinedResultIsMin();
    }

    @Test
    void testCombineWhenPartialChannelsIdle() throws Exception {
        super.testCombineWhenPartialChannelsIdle();
    }

    @Test
    void testCombineWhenAllChannelsIdle() throws Exception {
        super.testCombineWhenAllChannelsIdle();
    }

    @Test
    void testCombineWaitForAllChannels() throws Exception {
        super.testCombineWaitForAllChannels();
    }
}

class EventTimeWatermarkHandlerAugTest extends EventTimeWatermarkHandlerTest {

    @Test
    void testOneInputWatermarkHandler() throws Exception {
        super.testOneInputWatermarkHandler();
    }

    @Test
    void testTwoInputWatermarkHandler() throws Exception {
        super.testTwoInputWatermarkHandler();
    }
}

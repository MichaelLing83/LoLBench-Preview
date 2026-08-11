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

package org.apache.flink.client.program.rest.retry;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** P2P stability probes for client retry behavior unrelated to window extensions. */
class ExponentialWaitStrategyFlip501AugTest {

    @Test
    void testSleepTimeUsesConfiguredCapAfterOverflow() {
        assertThat(new ExponentialWaitStrategy(10L, 100L).sleepTime(63L)).isEqualTo(100L);
    }

    @Test
    void testNegativeAttemptIsRejected() {
        assertThatThrownBy(() -> new ExponentialWaitStrategy(10L, 100L).sleepTime(-1L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("attempt must not be negative");
    }
}

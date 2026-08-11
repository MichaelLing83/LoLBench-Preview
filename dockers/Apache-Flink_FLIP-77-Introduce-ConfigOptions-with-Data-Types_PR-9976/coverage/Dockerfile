# LoLBench coverage image: Apache-Flink PR-9976 (FLIP-77)
#
# Built ONCE per instance during curation/QA to measure how many lines of
# solution.patch are exercised by F2P and P2P.  Separate from the eval
# image to keep eval fast (no JaCoCo agent overhead).
#
# Usage:
#   docker build -t lolbench/apache-flink-flip-77-pr-9976-coverage:1 -f coverage/Dockerfile .
#   docker run --rm -v $(pwd)/coverage_out:/out \
#       lolbench/apache-flink-flip-77-pr-9976-coverage:1
#   → writes /out/coverage_report.json
#
# Differences from the eval image:
#   - JaCoCo agent (0.8.12) baked in at /opt/jacoco/jacocoagent.jar.
#   - JaCoCo CLI (jacococli.jar) for generating XML reports offline.
#   - Different ENTRYPOINT: run_coverage.sh.
#
# JaCoCo instruments bytecode at runtime via -javaagent, so no debug
# rebuild of flink-core is needed — we FROM the eval image and just
# add the agent + scripts.

ARG BASE_IMAGE=lolbench/apache-flink-flip-77-pr-9976:1
FROM ${BASE_IMAGE}

ARG JACOCO_VERSION=0.8.12

# Pull the JaCoCo agent + CLI artifacts into a stable path.  The CLI's
# "nodeps" classifier is a self-contained shaded jar; the agent jar's
# "runtime" classifier is the agent that surefire's -javaagent attaches.
RUN mkdir -p /opt/jacoco && \
    mvn -B dependency:get \
        -Dartifact=org.jacoco:org.jacoco.agent:${JACOCO_VERSION}:jar:runtime \
        -Dtransitive=false && \
    mvn -B dependency:get \
        -Dartifact=org.jacoco:org.jacoco.cli:${JACOCO_VERSION}:jar:nodeps \
        -Dtransitive=false && \
    cp "/root/.m2/repository/org/jacoco/org.jacoco.agent/${JACOCO_VERSION}/org.jacoco.agent-${JACOCO_VERSION}-runtime.jar" \
       /opt/jacoco/jacocoagent.jar && \
    cp "/root/.m2/repository/org/jacoco/org.jacoco.cli/${JACOCO_VERSION}/org.jacoco.cli-${JACOCO_VERSION}-nodeps.jar" \
       /opt/jacoco/jacococli.jar && \
    ls -la /opt/jacoco/

# Keep coverage runs in sync with local selector/spec cleanup even when
# the coverage image starts FROM a previously built eval image.
COPY spec.json solution.patch eval_tests.patch eval_tests_aug.patch \
     f2p.txt f2p_aug.txt p2p.txt p2p_aug.txt \
     /opt/lolbench/private/

COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

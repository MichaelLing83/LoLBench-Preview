# LoLBench coverage image: Apache-Kafka PR-7378 (KIP-470)
ARG BASE_IMAGE=lolbench/apache-kafka-kip-470-pr-7378:1
FROM ${BASE_IMAGE}
USER root

ARG JACOCO_VERSION=0.8.12

RUN mkdir -p /opt/jacoco && \
    curl -fsSL -o /opt/jacoco/jacocoagent.jar \
        "https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/${JACOCO_VERSION}/org.jacoco.agent-${JACOCO_VERSION}-runtime.jar" && \
    curl -fsSL -o /opt/jacoco/jacococli.jar \
        "https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/${JACOCO_VERSION}/org.jacoco.cli-${JACOCO_VERSION}-nodeps.jar" && \
    ls -la /opt/jacoco/

COPY solution.patch \
     eval_tests.patch \
     eval_tests_aug.patch \
     f2p.txt \
     p2p.txt \
     f2p_aug.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

# LoLBench coverage image: Apache-Flink PR-25978 (FLIP-499 Event Time Watermarks)
ARG BASE_IMAGE=lolbench/apache-flink-flip-499-pr-25978:1
FROM ${BASE_IMAGE}
USER root

ARG JACOCO_VERSION=0.8.12

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
    find /root/.m2/repository -name '_remote.repositories' -exec \
        sed -i 's/>redhat=/>central=/g; s/>redhat-ga=/>central=/g' {} + && \
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

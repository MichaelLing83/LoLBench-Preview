# LoLBench exact Maven-warm base for Apache-Flink PR-25731 (FLIP-467).
#
# The previous unexecutable reason was Maven cache drift against the
# shared Flink 2.x warm image. This base warms dependencies at the PR head,
# including the shaded artifacts pinned by this commit family, then removes
# the checkout. Eval still starts from base_commit and runs offline.
FROM python:3.11-slim AS pysrc

FROM maven:3-eclipse-temurin-17

COPY --from=pysrc /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=pysrc /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=pysrc /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=pysrc /usr/local/lib/libpython3.11.so.1.0 /usr/local/lib/libpython3.11.so.1.0

ARG WARMUP_COMMIT=cb40b8ad46441836fbdac39a785d4c65d45d71be

ENV MAVEN_OPTS="-Xmx5g -XX:ReservedCodeCacheSize=512m" \
    MVN_OPTS="-B -fae"

WORKDIR /workspace
RUN ldconfig && python3 --version

RUN git init flink-warm && \
    cd flink-warm && \
    git remote add origin https://github.com/apache/flink.git && \
    git fetch --no-tags origin ${WARMUP_COMMIT} && \
    git checkout ${WARMUP_COMMIT}

RUN cd /workspace/flink-warm && \
    mvn ${MVN_OPTS} \
        -DskipTests -Dfast \
        -Drat.skip=true -Dcheckstyle.skip=true -Dspotbugs.skip=true \
        -Dspotless.check.skip=true -Dmaven.javadoc.skip=true \
        -Denforcer.skip=true -Djapicmp.skip=true -Dscalastyle.skip=true \
        -pl flink-tests,flink-clients -am \
        install 2>&1 | tail -80

RUN cd /workspace/flink-warm && \
    for pl_test in \
        "flink-clients|org.apache.flink.client.cli.ClientOptionsTest" \
        "flink-tests|org.apache.flink.test.streaming.api.environment.LocalStreamEnvironmentITCase" \
        ; do \
      pl=$(echo "$pl_test" | cut -d'|' -f1); \
      tst=$(echo "$pl_test" | cut -d'|' -f2); \
      echo "[lolbench-warm] mvn test pl=$pl test=$tst"; \
      mvn ${MVN_OPTS} \
          -DskipITs -Dfast \
          -Drat.skip=true -Dcheckstyle.skip=true -Dspotbugs.skip=true \
          -Dspotless.check.skip=true -Dmaven.javadoc.skip=true \
          -Dsurefire.failIfNoSpecifiedTests=false \
          -Denforcer.skip=true -Djapicmp.skip=true -Dscalastyle.skip=true \
          -pl "$pl" -am \
          -Dtest="$tst" \
          test 2>&1 | tail -20 || true ; \
    done

RUN cd /workspace/flink-warm && \
    for art in \
        "org.apache.flink:flink-shaded-netty:4.1.100.Final-19.0" \
        "org.apache.flink:flink-shaded-swagger:19.0" \
        "org.apache.flink:flink-shaded-zookeeper-3:3.7.2-19.0" \
        "org.apache.flink:flink-shaded-jackson-module-jsonSchema:2.15.3-19.0" \
        "org.mockito:mockito-subclass:5.14.2" \
        "org.apache.maven.surefire:surefire-junit-platform:3.2.2" \
        "org.junit.platform:junit-platform-launcher:1.11.0" \
        "org.junit.platform:junit-platform-launcher:1.11.4" \
        "org.opentest4j:opentest4j:1.3.0" \
        "org.jacoco:org.jacoco.agent:0.8.12:jar:runtime" \
        "org.jacoco:org.jacoco.cli:0.8.12:jar:nodeps" \
        ; do \
      mvn ${MVN_OPTS} dependency:get \
          -Dartifact="$art" -Dtransitive=true \
          -DremoteRepositories=central::default::https://repo.maven.apache.org/maven2/ \
          2>&1 | tail -6 || true ; \
    done

RUN find /root/.m2/repository -name '_remote.repositories' -exec \
    sed -i 's/>redhat=/>central=/g; s/>redhat-ga=/>central=/g; s/>flink-public=/>central=/g' {} + && \
    rm -rf /workspace/flink-warm

WORKDIR /workspace

# LoLBench eval image: Apache-Flink PR-26567 (FLIP-498 AsyncTableFunction)
ARG BASE_IMAGE=lolbench/flink-base-jdk17:1
FROM ${BASE_IMAGE}

# --- Inlined Maven warm-up (folded in from the former shared
# lolbench/flink-mvn-warm-jdk17-2x:1 base image so this bundle rebuilds from
# flink-base-jdk17 without an external warm-base directory). Pre-resolves the
# shared Flink 2.x dependency tree so the hermetic --network=none eval build
# works offline. ---
ARG WARMUP_COMMIT=1a7c0f1bcdc92d550d38a85fee1900572e6aaac5

RUN mkdir -p /workspace

WORKDIR /workspace
RUN git init flink-warm && \
    cd flink-warm && \
    git remote add origin https://github.com/apache/flink.git && \
    git fetch --no-tags origin ${WARMUP_COMMIT} && \
    git checkout ${WARMUP_COMMIT}

# `mvn install -DskipTests` pulls the entire dep tree.  We add the major
# modules likely to host F2P / P2P selectors across the 18 FLIP 2.x
# instances: clients, table-{api-java, runtime, planner}, streaming,
# runtime, datastream-api, datastream-impl, state-backends/rocksdb.
RUN cd /workspace/flink-warm && \
    mvn ${MVN_OPTS} -B -fae \
        -DskipTests -Dfast \
        -Drat.skip=true -Dcheckstyle.skip=true -Dspotbugs.skip=true \
        -Dspotless.check.skip=true \
        -pl flink-clients,flink-streaming-java,flink-runtime,flink-table/flink-table-runtime,flink-table/flink-table-api-java,flink-table/flink-table-planner,flink-datastream-api,flink-datastream,flink-state-backends/flink-statebackend-rocksdb \
        -am \
        install 2>&1 | tail -30

# Run REAL tests to force surefire-junit-platform + transitive deps
# (opentest4j, junit-platform-launcher, junit-platform-engine, ...)
# into the cache.  surefire only resolves the provider when it actually
# encounters a JUnit5 test; --network=none later would otherwise miss it.
RUN cd /workspace/flink-warm && \
    for pl_test in \
        "flink-clients|org.apache.flink.client.cli.ClientOptionsTest" \
        "flink-table/flink-table-runtime|org.apache.flink.table.data.DecimalDataTest" \
        "flink-streaming-java|org.apache.flink.streaming.api.environment.StreamExecutionEnvironmentTest" \
        ; do \
      pl=$(echo "$pl_test" | cut -d'|' -f1); \
      tst=$(echo "$pl_test" | cut -d'|' -f2); \
      echo "[lolbench-warm] mvn test pl=$pl test=$tst"; \
      mvn ${MVN_OPTS} -B -fae \
          -DskipITs -Dfast \
          -Drat.skip=true -Dcheckstyle.skip=true -Dspotbugs.skip=true \
          -Dspotless.check.skip=true \
          -pl "$pl" -am \
          -Dtest="$tst" \
          test 2>&1 | tail -5 || true ; \
    done

# Pin the surefire/junit family explicitly so any version Flink 2.x
# resolves is in the cache.  Flink 2.2-SNAPSHOT uses junit5 1.11.x.
RUN for art in \
        "org.apache.maven.surefire:surefire-junit-platform:3.2.2" \
        "org.apache.maven.surefire:surefire-junit47:3.2.2" \
        "org.apache.maven.surefire:surefire-junit4:3.2.2" \
        "org.junit.platform:junit-platform-launcher:1.11.0" \
        "org.junit.platform:junit-platform-launcher:1.11.4" \
        "org.opentest4j:opentest4j:1.2.0" \
        "org.opentest4j:opentest4j:1.3.0" \
        ; do \
      cd /workspace/flink-warm && \
      mvn ${MVN_OPTS} -B dependency:get \
          -Dartifact="$art" -Dtransitive=true \
          -DremoteRepositories=central::default::https://repo.maven.apache.org/maven2/ \
          2>&1 | tail -3 || true ; \
    done

# Maven Resolver tracks per-artifact source repo in _remote.repositories.
# Flink's pom declares `redhat` as a side repo (for one Jackson variant);
# Maven may stamp un-related artifacts as `>redhat=` based on which repo
# it tried first.  Under offline mode it then refuses to use them.
# Rewrite all markers to point at `central` so offline runs trust them.
RUN find /root/.m2/repository -name '_remote.repositories' -exec \
    sed -i 's/>redhat=/>central=/g; s/>redhat-ga=/>central=/g; s/>flink-public=/>central=/g' {} +

# Free disk: drop the warmup checkout (cache lives in /root/.m2).
RUN rm -rf /workspace/flink-warm

WORKDIR /workspace
# --- end inlined warm-up ---

ARG BASE_COMMIT=7309fe832cb303c9adf6bfb441790e3d293908fe
ARG MERGE_COMMIT=b1fd0b8f1f666f7c4186585ea5be31111efbbc4e

RUN mkdir -p /opt/lolbench/private /in /out /workspace

WORKDIR /workspace
RUN git init flink && \
    cd flink && \
    git remote add origin https://github.com/apache/flink.git && \
    git fetch --no-tags origin ${MERGE_COMMIT} && \
    git checkout ${BASE_COMMIT} && \
    git config user.email lolbench@local && \
    git config user.name lolbench && \
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then \
      git add -A && git -c commit.gpgsign=false commit -q -m "LoLBench environment overlay"; \
    fi && \
    git tag -f base && git tag -f lolbench-base && \
    git for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags | \
      while read ref; do \
        case "$ref" in refs/tags/base|refs/tags/lolbench-base) ;; *) git update-ref -d "$ref" ;; esac; \
      done && \
    ( git remote remove origin 2>/dev/null || true ) && \
    rm -f .git/FETCH_HEAD && \
    git reflog expire --expire=now --all && \
    git repack -Ad && \
    git prune --expire=now && \
    git config --global --add safe.directory /workspace/flink

# Pre-build the modules our F2P + P2P need (flink-table-planner is the
# F2P target, flink-clients is the P2P target).
RUN cd /workspace/flink && \
    mvn -B -fae -DskipTests \
        -Dspotless.check.skip=true -Drat.skip=true -Dcheckstyle.skip=true \
        -Dmaven.javadoc.skip=true -Denforcer.skip=true \
        -Dspotbugs.skip=true -Djapicmp.skip=true \
        -pl flink-table/flink-table-planner,flink-clients -am \
        install 2>&1 | tail -40

# Real-test prewarm to land surefire-junit-platform + transitive deps
# for these modules' specific surefire version.
RUN cd /workspace/flink && \
    mvn -B -fae -DskipITs -Dfast \
        -Drat.skip=true -Dcheckstyle.skip=true -Dspotbugs.skip=true \
        -Dspotless.check.skip=true -Djapicmp.skip=true \
        -pl flink-clients -am \
        -Dtest=org.apache.flink.client.cli.ClientOptionsTest \
        test 2>&1 | tail -10 || true ; \
    find /root/.m2/repository -name '_remote.repositories' -exec \
        sed -i 's/>redhat=/>central=/g; s/>redhat-ga=/>central=/g' {} +

COPY spec.json solution.patch eval_tests.patch eval_tests_aug.patch omitted.patch \
     f2p.txt p2p.txt f2p_aug.txt p2p_aug.txt \
     /opt/lolbench/private/
COPY run_tests.sh /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_tests.sh

ENTRYPOINT ["/opt/lolbench/private/run_tests.sh"]

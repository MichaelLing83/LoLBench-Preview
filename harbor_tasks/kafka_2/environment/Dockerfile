# LoLBench eval image: Apache-Kafka PR-11572 (KIP-769)
ARG BASE_IMAGE=lolbench/kafka-base-jdk11-gradle733:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=066cdc8c621dfc4d26e12ee539368d6c1eb2707f
ARG MERGE_COMMIT=029a14b530dcaab980faee4fa18c925b95db3122

RUN mkdir -p /opt/lolbench/private /in /out /workspace

WORKDIR /workspace
RUN git init kafka && \
    cd kafka && \
    git remote add origin https://github.com/apache/kafka.git && \
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
    git config --global --add safe.directory /workspace/kafka

# Kafka 3.2 uses settings repos that include mavenCentral by default;
# grgit 4.x is on Maven Central from 4.1.x onwards.  Kafka 3.2 pins
# grgit 4.x but still has the JCenter classpath line — strip it for
# safety (Maven Central will resolve grgit correctly anyway).
RUN cd /workspace/kafka && \
    if grep -q "jcenter\|bintray" build.gradle 2>/dev/null; then \
      sed -i 's|^import org.ajoberstar.grgit.Grgit||' build.gradle && \
      sed -i '/classpath "org.ajoberstar.grgit:grgit-core/d' build.gradle && \
      grep -n 'Grgit\|grgit' build.gradle || true; \
    fi

# Warm dep cache for the modules our F2P + P2P need.
RUN cd /workspace/kafka && \
    gradle --no-daemon -PscalaVersion=2.13 \
        -x test -x rat -x checkstyleMain -x checkstyleTest \
        -x spotbugsMain -x spotbugsTest \
        :clients:jar :connect:json:classes :connect:runtime:classes \
        2>&1 | tail -120 && \
    echo "--- gradle cache size ---" && \
    du -sh /root/.gradle 2>/dev/null

# Pre-warm jacoco-agent + scoverage via no-match test (same trick as
# KIP-470/595).
RUN cd /workspace/kafka && \
    gradle --no-daemon -PscalaVersion=2.13 \
        -x rat -x checkstyleMain -x checkstyleTest \
        -x spotbugsMain -x spotbugsTest \
        :connect:runtime:test :connect:json:test \
        --tests org.apache.kafka.LOLBENCH_PREWARM_NONEXISTENT \
        --rerun-tasks --continue \
        2>&1 | tail -40 ; \
    gradle --no-daemon -PscalaVersion=2.13 -PenableTestCoverage=true \
        -x rat -x checkstyleMain -x checkstyleTest \
        -x spotbugsMain -x spotbugsTest \
        :connect:runtime:test :connect:json:test \
        --tests org.apache.kafka.LOLBENCH_PREWARM_NONEXISTENT \
        --rerun-tasks --continue \
        2>&1 | tail -40 ; \
    echo "--- gradle cache size after test pre-warm ---" && \
    du -sh /root/.gradle 2>/dev/null && \
    git add build.gradle && \
    git -c commit.gpgsign=false commit --amend --no-edit -q

# Harbor runtime adapter: keep the image public/agent-safe.
RUN mkdir -p /opt/lolbench /logs/artifacts /logs/agent /logs/verifier /in /out && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit
RUN chmod +x /usr/local/bin/lolbench-submit && \
    git config --global --add safe.directory /workspace/kafka && \
    if [ -d /workspace/kafka/.git ]; then \
      cd /workspace/kafka && git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt; \
    else \
      : > /opt/lolbench/base_untracked.txt; \
    fi && \
    chown -R agent:agent /workspace/kafka /logs
USER agent
WORKDIR /workspace/kafka
ENV LOLBENCH_INSTANCE_ID=kafka_2
ENV LOLBENCH_SOURCE_SLUG=Apache-Kafka_KIP-769-Connect-APIs-to-list-all-connector-plugins-and-retri_PR-11572

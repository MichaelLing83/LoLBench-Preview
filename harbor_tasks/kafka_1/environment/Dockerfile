# LoLBench eval image: Apache-Kafka PR-7378 (KIP-470)
#   Requirement: TopologyTestDriver test input/output usability — new
#                TestInputTopic / TestOutputTopic public types.
#   base_commit: 0de61a4683b92bdee803c51211c3277578ab3edf
#                (parent of squash-merge a5a6938c)
#
# Layered:
#   layer 1: eclipse-temurin:8-jdk
#   layer 2: lolbench/kafka-base-jdk8-gradle562:1   (JDK 8 + Gradle 5.6.2)
#   layer 3: THIS image                              (source @ base_commit
#                                                     + warm Gradle cache
#                                                     + private bundle)

ARG BASE_IMAGE=lolbench/kafka-base-jdk8-gradle562:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=0de61a4683b92bdee803c51211c3277578ab3edf
ARG MERGE_COMMIT=a5a6938c69f4310f7ec519036f0df77d8022326a

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

# Same Grgit strip as KIP-460 — Kafka 2.4 still pulls org.ajoberstar.grgit
# from JCenter, which is defunct since 2021.
RUN cd /workspace/kafka && \
    sed -i '/classpath "org.ajoberstar.grgit:grgit-core/d' build.gradle && \
    sed -i 's|^import org.ajoberstar.grgit.Grgit||' build.gradle && \
    sed -i 's|def repo = Grgit.open(currentDir: project.getRootDir())|def repo = null|' build.gradle && \
    sed -i 's|excludes = new ArrayList<String>(repo.clean(ignore: false, directories: true, dryRun: true))|excludes = new ArrayList<String>()|' build.gradle && \
    grep -n "Grgit\|grgit" build.gradle || echo "Grgit references successfully removed"

# Warm the Gradle dep cache. Use `:streams:test-utils:classes` and
# `:streams:examples:classes` instead of `:jar` to avoid pulling the
# copyDependantLibs trap that drags `:clients:compileTestJava` into the
# build (same lesson as KIP-460).
#
# `:streams:test-utils:classes` triggers transitively: :generator,
# :clients main, :connect:json main, :streams main, :streams:test-utils
# main.  That covers everything the eval-time build needs.
RUN cd /workspace/kafka && \
    gradle --no-daemon -PscalaVersion=2.12 \
        -x test -x rat -x checkstyleMain -x checkstyleTest \
        -x spotbugsMain -x spotbugsTest \
        :clients:jar :streams:test-utils:classes :streams:examples:classes \
        :connect:json:classes \
        2>&1 | tail -120 && \
    echo "--- gradle cache size ---" && \
    du -sh /root/.gradle 2>/dev/null

# ---- Pre-warm jacoco-agent + everything else the Test task pulls.
# Kafka 2.4 applies the `jacoco` plugin to every non-:core project; the
# `jacocoAgent` configuration resolves `org.jacoco:org.jacoco.agent:0.8.3`
# only at Test task execution (not at `dependencies --configuration`
# resolution, which fetches only the POM).  With --network=none at eval
# time the missing JAR aborts the Test task before any JUnit XML lands
# on disk.
#
# Force the JAR into the cache by running each test task once with a
# no-match `--tests` filter: Gradle still constructs the Test task,
# initialises its agent jvmArgs, and downloads the agent JAR — then
# exits cleanly without executing any test methods because the filter
# matched zero classes.
#
# This also caches every other late-resolved dep (rocksdbjni native,
# slf4jlog4j, etc.) so the eval-time run is fully offline-ready.
RUN cd /workspace/kafka && \
    gradle --no-daemon -PscalaVersion=2.12 \
        -x rat -x checkstyleMain -x checkstyleTest \
        -x spotbugsMain -x spotbugsTest \
        :streams:test-utils:test :streams:examples:test :connect:json:test \
        --tests org.apache.kafka.LOLBENCH_PREWARM_NONEXISTENT \
        --rerun-tasks \
        2>&1 | tail -40 && \
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
ENV LOLBENCH_INSTANCE_ID=kafka_1
ENV LOLBENCH_SOURCE_SLUG=Apache-Kafka_KIP-470_TopologyTestDriver-test-input-and-output-usability-improvements_PR-7378

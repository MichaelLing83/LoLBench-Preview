# LoLBench eval image: Apache-Flink PR-9976 (FLIP-77)
#   Requirement: Introduce ConfigOptions with Data Types
#   base_commit: 005bda9be361ffe6c371ebefed32e614cbacd876
#                (parent of the PR's single FLINK-14493 commit
#                b7cd6a98; the CSV value 96640cad... is the GitHub
#                PR-base, but four unrelated commits sit between
#                96640cad and b7cd6a98 — they get filtered out by
#                anchoring at 005bda9b)
#
# Agent-facing contract (run by the evaluator):
#   docker run --rm \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/apache-flink-flip-77-pr-9976:1
#
# Layered build:
#   layer 1: eclipse-temurin:8-jdk
#   layer 2: lolbench/flink-base-jdk8:1   (JDK + Maven + git + python3)
#   layer 3: THIS image                    (source @ base_commit
#                                           + pre-built flink-core
#                                           + flink-clients + private bundle)

ARG BASE_IMAGE=lolbench/flink-base-jdk8:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=005bda9be361ffe6c371ebefed32e614cbacd876
ARG MERGE_COMMIT=b7cd6a984750d7dd98e6408f3703b1978b14355a

RUN mkdir -p /opt/lolbench/private /in /out /workspace

# ---- Source tree at base_commit ----------------------------------------
# GitHub blocks shallow fetches of arbitrary non-tip SHAs.  Workaround:
# fetch from MERGE_COMMIT at depth high enough to include BASE_COMMIT
# (the PR has 5 chained commits; depth=10 is comfortable).  Then check
# out BASE_COMMIT and reset history to a ancestor-preserving baseline for
# cheap `git reset --hard` cycles at eval time.
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

# ---- Pre-build flink-core + flink-clients (with -am for transitive
# deps).  Skipping tests keeps this to a single ~10-15 min build at
# Flink 1.10 scale.  The base_commit build is baked into the image so
# eval-time runs are incremental rebuilds (~1-3 min when only flink-
# core's main sources change).
#
# Maven invocation:
#   -B            batch mode
#   -fae          fail-at-end (don't stop on first failure)
#   -DskipTests   skip test execution (test-compile still runs and
#                 packages test-jars that other modules depend on)
#   -am           also-make: build dependent modules transitively
#   -pl           project-list: limit to flink-core + flink-clients
#
# We also disable rat/spotless and other style plugins to save time.
RUN cd /workspace/flink && \
    mvn -B -fae \
        -pl flink-core,flink-clients \
        -am -DskipTests \
        -Drat.skip=true \
        -Dcheckstyle.skip=true \
        -Dmaven.javadoc.skip=true \
        -Denforcer.skip=true \
        install

# ---- Pre-warm Surefire / JUnit-4 provider jars into the local Maven
# repo.  Eval runs with --network=none, so Surefire must not need to
# dial out for surefire-junit4:... etc. at test time.
#
# Flink 1.10 era uses JUnit 4 (org.junit:junit:4.x) — no JUnit-platform
# resolution path is needed.  We still pull both provider candidates
# explicitly to mirror the FLIP-335 pattern and remain robust against
# auto-detection differences.
RUN mvn -B dependency:get \
        -Dartifact=org.apache.maven.surefire:surefire-junit4:2.22.1 \
        -Dtransitive=true && \
    mvn -B dependency:get \
        -Dartifact=org.apache.maven.surefire:surefire-junit47:2.22.1 \
        -Dtransitive=true

# ---- Eval bundle ------------------------------------------------------
COPY spec.json \
     solution.patch \
     eval_tests.patch \
     f2p.txt \
     p2p.txt \
     /opt/lolbench/private/
COPY eval_tests_aug.patch \
     f2p_aug.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY run_tests.sh /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_tests.sh

ENTRYPOINT ["/opt/lolbench/private/run_tests.sh"]

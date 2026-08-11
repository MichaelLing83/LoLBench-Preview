# LoLBench eval image: Apache-Flink PR-25731 (FLIP-467 generalized watermarks)
ARG BASE_IMAGE=lolbench/apache-flink-flip-467-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=f0c8f18ee09297c4c92b36d8ce7d0e0259f80178

RUN mkdir -p /opt/lolbench/private /in /out /workspace

WORKDIR /workspace
RUN git init flink && \
    cd flink && \
    git remote add origin https://github.com/apache/flink.git && \
    git fetch --no-tags origin ${BASE_COMMIT} && \
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

COPY spec.json \
     solution.patch \
     eval_tests.patch \
     eval_tests_aug.patch \
     omitted.patch \
     f2p.txt \
     f2p_aug.txt \
     p2p.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY run_tests.sh /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_tests.sh

ENTRYPOINT ["/opt/lolbench/private/run_tests.sh"]

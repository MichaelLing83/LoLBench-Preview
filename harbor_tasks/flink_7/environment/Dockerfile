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

# Harbor runtime adapter: keep the image public/agent-safe.
RUN mkdir -p /opt/lolbench /logs/artifacts /logs/agent /logs/verifier /in /out && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit
RUN chmod +x /usr/local/bin/lolbench-submit && \
    git config --global --add safe.directory /workspace/flink && \
    if [ -d /workspace/flink/.git ]; then \
      cd /workspace/flink && git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt; \
    else \
      : > /opt/lolbench/base_untracked.txt; \
    fi && \
    chown -R agent:agent /workspace/flink /logs
USER agent
WORKDIR /workspace/flink
ENV LOLBENCH_INSTANCE_ID=flink_7
ENV LOLBENCH_SOURCE_SLUG=Apache-Flink_FLIP-467-Introduce-Generalized-Watermarks_PR-25731

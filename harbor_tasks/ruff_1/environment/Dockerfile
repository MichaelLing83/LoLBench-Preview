# LoLBench eval image: Ruff PR-9599 (Issue-8368 — allow CLI config-option overrides)
ARG BASE_IMAGE=rust:1.76-bookworm
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=b21ba71ef4b897cbb9e3c402f081887b650b6448

RUN mkdir -p /opt/lolbench/private /in /out /workspace && \
    apt-get update -qq && apt-get install -y -qq --no-install-recommends \
        git ca-certificates python3 && \
    rm -rf /var/lib/apt/lists/* && \
    rustup component add rustfmt clippy

WORKDIR /workspace
RUN git init ruff && \
    cd ruff && \
    git remote add origin https://github.com/astral-sh/ruff.git && \
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
    git config --global --add safe.directory /workspace/ruff

# Warm the cargo dep cache and pre-compile so subsequent test runs
# don't redo the full link.  Build the integration-test binaries we'll
# exercise (format + lint + integration_test + show_settings + resolve_files).
RUN set -x; cd /workspace/ruff && \
    cargo fetch 2>&1 | tail -10 ; \
    cargo build --tests -p ruff --test format --test lint --test integration_test --test show_settings --test resolve_files 2>&1 | tail -30 ; \
    echo "--- cargo cache size ---" && \
    du -sh /usr/local/cargo /workspace/ruff/target 2>/dev/null ; \
    true

# Harbor runtime adapter: keep the image public/agent-safe.
RUN mkdir -p /opt/lolbench /logs/artifacts /logs/agent /logs/verifier /in /out && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit
RUN chmod +x /usr/local/bin/lolbench-submit && \
    git config --global --add safe.directory /workspace/ruff && \
    if [ -d /workspace/ruff/.git ]; then \
      cd /workspace/ruff && git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt; \
    else \
      : > /opt/lolbench/base_untracked.txt; \
    fi && \
    chown -R agent:agent /workspace/ruff /logs
USER agent
WORKDIR /workspace/ruff
ENV LOLBENCH_INSTANCE_ID=ruff_1
ENV LOLBENCH_SOURCE_SLUG=Ruff_Issue-8368_Allow-override-of-configuration-options-via-the-CLI_PR-9599

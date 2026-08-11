# LoLBench eval image: FastAPI PR-4871 (PEP-593 Annotated for dependency injection)
ARG BASE_IMAGE=lolbench/fastapi-base-py310:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=ef176c663195489b44030bfe1fb94a317762c8d5
ARG MERGE_COMMIT=375513f11494bc3499050ad2a0d378fb6e37ca98

RUN mkdir -p /opt/lolbench/private /in /out /workspace

WORKDIR /workspace
RUN git init fastapi && \
    cd fastapi && \
    git remote add origin https://github.com/fastapi/fastapi.git && \
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
    git config --global --add safe.directory /workspace/fastapi

# Install FastAPI itself in editable mode at base.
RUN cd /workspace/fastapi && pip install -e .

# Harbor runtime adapter: keep the image public/agent-safe.
RUN mkdir -p /opt/lolbench /logs/artifacts /logs/agent /logs/verifier /in /out && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit
RUN chmod +x /usr/local/bin/lolbench-submit && \
    git config --global --add safe.directory /workspace/fastapi && \
    if [ -d /workspace/fastapi/.git ]; then \
      cd /workspace/fastapi && git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt; \
    else \
      : > /opt/lolbench/base_untracked.txt; \
    fi && \
    chown -R agent:agent /workspace/fastapi /logs
USER agent
WORKDIR /workspace/fastapi
ENV LOLBENCH_INSTANCE_ID=fastapi_1
ENV LOLBENCH_SOURCE_SLUG=FastAPI_PEP-593_Flexible-function-and-variable-annotations_PR-4871

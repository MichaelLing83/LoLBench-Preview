# LoLBench coverage image: FastAPI PR-4871 (PEP 593 Annotated for dependency injection)
ARG BASE_IMAGE=lolbench/fastapi-base-py310:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=ef176c663195489b44030bfe1fb94a317762c8d5

RUN pip install "coverage[toml]>=6.5.0,<8.0"

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

RUN cd /workspace/fastapi && pip install -e .

COPY spec.json solution.patch eval_tests.patch eval_tests_aug.patch \
     f2p.txt p2p.txt f2p_aug.txt p2p_aug.txt \
     /opt/lolbench/private/
COPY coverage/run_coverage.sh coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

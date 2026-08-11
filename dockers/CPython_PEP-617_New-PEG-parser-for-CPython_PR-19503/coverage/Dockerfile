# LoLBench coverage image: CPython PR-19503 (PEP 617)
#
# Built ONCE per instance during curation/QA to measure how many lines
# of solution.patch are exercised by F2P and P2P.  Separate from the
# eval image to keep eval fast — the gcov instrumentation adds 2–3×
# wall-clock overhead per test run and requires a Debug build (-O0 + -g)
# whose object file sizes are 3–4× the Release build's.
#
# Usage:
#   docker build -t lolbench/cpython-pr-19503-coverage:1 -f coverage/Dockerfile .
#       -v $(pwd)/coverage_out:/out \
#       lolbench/cpython-pr-19503-coverage:1
#   → writes /out/coverage_report.json
#
# Differences from the eval image:
#   - Debug build (-O0 + -g) so gcov line counters match source 1:1.
#   - CFLAGS / LDFLAGS carry `--coverage` (= -fprofile-arcs + -ftest-coverage
#     for compile, -lgcov for link), so every .c file produces an adjacent
#     .gcno file at build time and an adjacent .gcda counter file at
#     run time.
#   - `gcovr` and `lcov` (from apt) are pre-installed for the analysis
#     phase in run_coverage.sh.
#
# The container still runs as root (trusted evaluator only invokes it),

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}
USER root

ARG BASE_COMMIT=a81849b0315277bb3937271174aaaa5059c0b445

# Coverage tooling (gcovr emits gcov JSON; lcov ships gcov shims for
# parallel test runs).  python3-pip pulls in setuptools so `pip install
# gcovr` would also work, but the apt build keeps the layer reproducible.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcovr \
        lcov \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/lolbench/private /in /out /workspace

# ---- Source tree at base_commit ---------------------------------------
WORKDIR /workspace
RUN git init cpython && \
    cd cpython && \
    git remote add origin https://github.com/python/cpython.git && \
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
    git config --global --add safe.directory /workspace/cpython

# ---- Pre-build CPython at base_commit, with gcov instrumentation -------
# `--coverage` on CFLAGS implies -fprofile-arcs -ftest-coverage at compile
# and the corresponding gcov bookkeeping calls at startup; on LDFLAGS it
# links libgcov so the counter snapshots get written at process exit.
# -O0 keeps source-to-line mapping 1:1; -g is needed for gcovr to
# resolve source filenames.  We deliberately do NOT pass
# --enable-pydebug — that adds reference-count debug bookkeeping that
# is orthogonal to coverage and roughly halves test speed again.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    CFLAGS="--coverage -O0 -g" \
    LDFLAGS="--coverage" \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Eval bundle + coverage scripts -----------------------------------
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
COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

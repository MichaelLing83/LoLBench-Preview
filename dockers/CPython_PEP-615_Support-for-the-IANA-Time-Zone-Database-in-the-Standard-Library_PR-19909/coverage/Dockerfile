# LoLBench coverage image: CPython PR-19909 (PEP 615: zoneinfo)
#
# Built ONCE per instance during curation/QA to measure how many lines
# of solution.patch are exercised by F2P and P2P.  Separate from the
# eval image so eval stays fast.
#
# zoneinfo has BOTH a Python implementation (Lib/zoneinfo/*.py, 1060
# new lines) AND a C accelerator (Modules/_zoneinfo.c, 2695 new lines).
# Coverage therefore needs two tools:
#   - coverage.py 7.4.4 (Python tracing) for Lib/zoneinfo/*.py
#   - gcov / gcovr for Modules/_zoneinfo.c
# We rebuild CPython at base_commit with `--coverage` C flags so every
# .c file (including the new Modules/_zoneinfo.c after solution.patch
# is applied) emits .gcno + .gcda counters.  coverage.py instruments
# Python-level tracing at run time without any compile-time change.
#
# Usage:
#   docker build -t lolbench/cpython-pr-19909-coverage:1 -f coverage/Dockerfile .
#   docker run --rm \
#       -v $(pwd)/coverage_out:/out \
#       lolbench/cpython-pr-19909-coverage:1
#   → writes /out/coverage_report.json

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=6e8cda91d92da72800d891b2fc2073ecbc134d98

# Coverage tooling: gcovr for C (Modules/_zoneinfo.c), pip+coverage for
# Python (Lib/zoneinfo/*.py).  lcov ships gcov shims used by gcovr.
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

# ---- Pre-build CPython at base_commit, gcov-instrumented --------------
# --coverage on CFLAGS implies -fprofile-arcs -ftest-coverage at compile,
# and the corresponding gcov bookkeeping at startup.  On LDFLAGS it
# links libgcov so counter snapshots get written at process exit.
# -O0 keeps source-to-line mapping 1:1; -g is needed for gcovr to
# resolve source filenames.  No --enable-pydebug because that doubles
# test wall-clock for no coverage gain.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    CFLAGS="--coverage -O0 -g" \
    LDFLAGS="--coverage" \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Install coverage.py against the freshly-built ./python -----------
RUN /workspace/cpython/python -m ensurepip --default-pip && \
    /workspace/cpython/python -m pip install --no-cache-dir coverage==7.4.4 && \
    /workspace/cpython/python -c "import coverage; print('coverage.py version:', coverage.__version__)"

# ---- Eval bundle + coverage scripts -----------------------------------
COPY spec.json \
     solution.patch \
     eval_tests.patch \
     eval_tests_aug.patch \
     f2p.txt \
     f2p_aug.txt \
     p2p.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

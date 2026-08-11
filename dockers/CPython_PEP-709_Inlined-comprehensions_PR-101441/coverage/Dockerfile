# LoLBench coverage image: CPython PR-101441 (PEP 709: Inlined Comprehensions)
#
# Built ONCE per instance during curation/QA to measure how many lines
# of solution.patch are exercised by F2P and P2P.  Separate from the
# eval image so eval stays fast.
#
# PEP 709 modifies BOTH C (15 files: compile.c, symtable.c, bytecodes.c,
# flowgraph.c, assemble.c, generated_cases.c.h, opcode_*.h, frameobject.c,
# pycore_*.h, Modules/_testinternalcapi.c — 4329 added lines and ~695
# removed) AND Python (2 files: Lib/opcode.py + Lib/importlib/
# _bootstrap_external.py — ~9 added lines).  Coverage therefore needs
# two tools:
#   - coverage.py 7.4.4 (Python tracing) for the 2 Lib files
#   - gcov / gcovr for the 15 C files
# We rebuild CPython at base_commit with `--coverage` C flags so every
# .c file emits .gcno + .gcda counters.
#
# Usage:
#   docker build -t lolbench/cpython-pr-101441-coverage:1 -f coverage/Dockerfile .
#   docker run --rm \
#       -v $(pwd)/coverage_out:/out \
#       lolbench/cpython-pr-101441-coverage:1
#   → writes /out/coverage_report.json

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=0aeda297931820436a50b78f4f7f0597274b5df4

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcovr \
        lcov \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/lolbench/private /in /out /workspace

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

# Pre-build CPython at base_commit with gcov instrumentation.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    CFLAGS="--coverage -O0 -g" \
    LDFLAGS="--coverage" \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

RUN /workspace/cpython/python -m ensurepip --default-pip && \
    /workspace/cpython/python -m pip install --no-cache-dir coverage==7.4.4 && \
    /workspace/cpython/python -c "import coverage; print('coverage.py version:', coverage.__version__)"

COPY spec.json \
     solution.patch \
     eval_tests.patch \
     eval_tests_aug.patch \
     f2p.txt \
     p2p.txt \
     f2p_aug.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

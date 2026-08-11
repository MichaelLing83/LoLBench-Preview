# LoLBench coverage image: CPython PR-31498 (PEP 680: tomllib)
#
# Built ONCE per instance during curation/QA to measure how many lines
# of solution.patch are exercised by F2P and P2P.  Separate from the
# eval image because coverage uses Python-level tracing (coverage.py)
# which is slow and produces large reports.
#
# tomllib is pure Python — there is no C to gcov.  All four files
# added by solution.patch live under Lib/tomllib/ as plain Python
# modules.  We therefore use `coverage.py` (PyPI) to measure line
# coverage of those four files (818 source lines).
#
# Usage:
#   docker build -t lolbench/cpython-pr-31498-coverage:1 -f coverage/Dockerfile .
#   docker run --rm \
#       -v $(pwd)/coverage_out:/out \
#       lolbench/cpython-pr-31498-coverage:1
#   → writes /out/coverage_report.json
#
# Differences from the eval image:
#   - Release build still (no debug build needed for coverage.py).
#   - `coverage` (PyPI) is installed against the freshly-built ./python
#     so the tracer runs under the same interpreter that runs the tests.
#   - No --coverage CFLAGS / no gcov / no gcovr / no lcov.

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=0b5a573ce8e8e90daad4d24b215aabb7356f4fce

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

# ---- Pre-build CPython at base_commit ---------------------------------
# Release build (no debug / no coverage CFLAGS).  Coverage measurement
# for tomllib happens at the Python level via coverage.py, not gcov.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Install coverage.py against the freshly-built ./python ------------
# We use the source distribution of coverage.py 7.4.4 fetched from
# files.pythonhosted.org via the apt-installed system python's pip
# wheel cache (which is offline-friendly via /var/cache/apt).  When
# the build is offline (--network=none for the container, but build
# uses default network), pip fetches from PyPI.
RUN /workspace/cpython/python -m ensurepip --default-pip && \
    /workspace/cpython/python -m pip install --no-cache-dir coverage==7.4.4 && \
    /workspace/cpython/python -c "import coverage; print('coverage.py version:', coverage.__version__)"

# Local-reference hardening runs after coverage installation because that step
# needs ensurepip.  Remove every bundled wheel, replace the fetched history
# with a parentless baseline, and prune the former commit graph so Tomli cannot
# be recovered from either the worktree or Git objects.
RUN cd /workspace/cpython && \
    git rm -f --ignore-unmatch -- Lib/ensurepip/_bundled/*.whl && \
    test -z "$(find Lib/ensurepip/_bundled -maxdepth 1 -type f -name '*.whl' -print -quit 2>/dev/null)" && \
    sanitized_tree=$(git write-tree) && \
    sanitized_commit=$(printf '%s\n' 'LoLBench sanitized base' | git commit-tree "$sanitized_tree") && \
    git reset --mixed "$sanitized_commit" && \
    git tag -f base && \
    git tag -f lolbench-base && \
    git for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags | \
      while read ref; do \
        case "$ref" in refs/tags/base|refs/tags/lolbench-base) ;; *) git update-ref -d "$ref" ;; esac; \
      done && \
    ( git remote remove origin 2>/dev/null || true ) && \
    rm -f .git/FETCH_HEAD .git/ORIG_HEAD && \
    git reflog expire --expire=now --all && \
    git repack -Ad && \
    git prune --expire=now && \
    unreachable=$(git fsck --unreachable --no-reflogs) && \
    test -z "$unreachable"
# coverage.py remains installed; only pip/ensurepip reference sources and
# package-manager caches are removed after installation.
RUN for root in /usr/local/lib /usr/lib; do \
      [ ! -d "$root" ] || find "$root" -type d \
        \( -path '*/site-packages/pip' -o -path '*/dist-packages/pip' -o \
           -name ensurepip -o -path '*/site-packages/tomli*' -o \
           -path '*/dist-packages/tomli*' \) \
        -prune -exec rm -rf '{}' +; \
    done && \
    rm -rf /usr/share/python-wheels /usr/share/python3-wheels \
           /root/.cache/pip /root/.cache/uv && \
    rm -f /usr/local/bin/pip /usr/local/bin/pip3 /usr/local/bin/pip3.* \
          /usr/bin/pip /usr/bin/pip3 /usr/bin/pip3.*

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

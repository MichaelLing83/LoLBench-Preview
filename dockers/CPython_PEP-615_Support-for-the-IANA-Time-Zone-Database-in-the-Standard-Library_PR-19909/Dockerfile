# LoLBench eval image: CPython PR-19909 (PEP 615: zoneinfo — Support for the IANA Time Zone Database)
#   Requirement: https://peps.python.org/pep-0615/
#   base_commit: 6e8cda91d92da72800d891b2fc2073ecbc134d98 (parent of squash-
#                merge commit 62972d9d73e83d6eea157617cc69500ffec9e3f0 —
#                see spec.json base_commit_note for why this overrides
#                the CSV value)
#
# Agent-facing contract (the agent does NOT run anything inside this image;
# the evaluator runs the container after the agent submits a solution.patch):
#
#   docker run --rm \
#       --network=none \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/cpython-pr-19909:1
#
# zoneinfo adds a C extension (Modules/_zoneinfo.c) and a pure-Python
# fallback. No special capabilities are needed.  The container stays
# --network=none with the default seccomp profile.
#
# Because the agent's code never executes here, the container runs every
# step as root — no agent UID, no chown of /usr/local, no runuser dance.
#
# Layered build per docs/executable_environment_plan.md §4:
#   layer 1: ubuntu:22.04
#   layer 2: lolbench/cpython-base:1    (toolchain + stdlib build deps)
#   layer 3: THIS image                  (cpython @ base_commit + built python + private bundle)

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=6e8cda91d92da72800d891b2fc2073ecbc134d98

# ---- Per-instance dirs ------------------------------------------------
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
# solution.patch adds the entire zoneinfo stdlib module:
#   - Lib/zoneinfo/*.py        (4 files, ~1060 lines pure Python)
#   - Modules/_zoneinfo.c      (2695 lines, the C accelerator)
# plus the build-system wiring to compile + install the C extension
# (configure / configure.ac / Makefile.pre.in / setup.py / Modules/Setup).
# Because configure.ac changes, the eval-time runner re-runs ./configure
# before `make` so setup.py picks up the new extension entry.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Eval bundle ------------------------------------------------------
# Local-reference hardening: retain only the approved base history.
RUN cd /workspace/cpython && \
    git for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags | \
      while read ref; do \
        case "$ref" in refs/tags/base|refs/tags/lolbench-base) ;; *) git update-ref -d "$ref" ;; esac; \
      done && \
    ( git remote remove origin 2>/dev/null || true ) && \
    rm -f .git/FETCH_HEAD && \
    git reflog expire --expire=now --all && \
    git repack -Ad && \
    git prune --expire=now && \
    unreachable=$(git fsck --unreachable --no-reflogs) && \
    test -z "$unreachable" && \
    chown -R root:root .git
# Remove installed Python source copies/backports and package caches.
RUN for root in /usr/local/lib /usr/lib; do \
      [ ! -d "$root" ] || find "$root" -type d \
        \( -path '*/site-packages/pip' -o -path '*/dist-packages/pip' -o \
           -name ensurepip -o -name tomllib -o -name zoneinfo -o \
           -path '*/site-packages/tomli*' -o -path '*/dist-packages/tomli*' -o \
           -path '*/site-packages/typing_extensions*' -o -path '*/dist-packages/typing_extensions*' -o \
           -path '*/site-packages/exceptiongroup*' -o -path '*/dist-packages/exceptiongroup*' \) \
        -prune -exec rm -rf '{}' +; \
      [ ! -d "$root" ] || find "$root" -type f \
        \( -name 'tomli*.py' -o -name 'typing_extensions*.py' -o -name 'exceptiongroup*.py' \) -delete; \
    done && \
    rm -rf /usr/share/python-wheels /usr/share/python3-wheels \
           /root/.cache/pip /root/.cache/uv /home/agent/.cache/pip /home/agent/.cache/uv && \
    rm -f /usr/local/bin/pip /usr/local/bin/pip3 /usr/local/bin/pip3.* \
          /usr/bin/pip /usr/bin/pip3 /usr/bin/pip3.* && \
    for p in /usr/local/lib/python*/site-packages /usr/lib/python*/dist-packages; do \
      [ ! -d "$p" ] || { chown -R root:root "$p"; chmod -R go-w "$p"; chmod 0711 "$p"; }; \
    done
# PEP 615 hardening: Ubuntu's Python 3.10 ships the finished target as a
# compiled extension even after the zoneinfo Python package is removed.
RUN find /usr/lib /usr/local/lib \( -type f -o -type l \) \
      \( -name '_zoneinfo*.so' -o -name '_zoneinfo*.py' -o -name '_zoneinfo*.pyc' \) \
      -delete && \
    leaked=$(find /usr/lib /usr/local/lib \( -type f -o -type l \) \
      \( -name '_zoneinfo*.so' -o -name '_zoneinfo*.py' -o -name '_zoneinfo*.pyc' \) \
      -print -quit) && \
    test -z "$leaked" && \
    if python3 -c 'import _zoneinfo' 2>/dev/null; then \
      echo 'unexpected released _zoneinfo oracle after hardening' >&2; exit 1; \
    fi

COPY spec.json \
     solution.patch \
     eval_tests.patch \
     eval_tests_aug.patch \
     f2p.txt \
     f2p_aug.txt \
     p2p.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY run_tests.sh /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_tests.sh

ENTRYPOINT ["/opt/lolbench/private/run_tests.sh"]

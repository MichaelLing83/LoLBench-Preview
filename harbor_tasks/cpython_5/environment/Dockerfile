# LoLBench eval image: CPython PR-31498 (PEP 680: tomllib — Support for Parsing TOML in the Standard Library)
#   Requirement: https://peps.python.org/pep-0680/
#   base_commit: 0b5a573ce8e8e90daad4d24b215aabb7356f4fce (parent of squash-
#                merge commit 591f6754b56cb7f6c31fce8c22528bdf0a99556c —
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
#       lolbench/cpython-pr-31498:1
#
# tomllib is a pure-Python module (Lib/tomllib/*.py); no special capabilities
# are needed.  The container stays --network=none with the default seccomp
# profile.
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

ARG BASE_COMMIT=0b5a573ce8e8e90daad4d24b215aabb7356f4fce

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
# A single full build at base_commit warms the build tree.  solution.patch
# only ADDS Python files (Lib/tomllib/*.py — 4 files, 818 lines) plus a
# single-line entry in Python/stdlib_module_names.h.  The C portion of
# the build is therefore essentially identical pre/post; only `make`
# regenerates the frozen stdlib module list when stdlib_module_names.h
# changes.
#
# Build flags rationale:
#   --prefix=/usr/local : keep system layout; we use ./python, not the
#                         installed binary, so the install step is omitted
#   --with-pydebug      : OFF (default)
#   --enable-shared     : OFF (default)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Eval bundle ------------------------------------------------------

# Harbor runtime adapter: keep the image public/agent-safe.
RUN mkdir -p /opt/lolbench /logs/artifacts /logs/agent /logs/verifier /in /out && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit
RUN chmod +x /usr/local/bin/lolbench-submit && \
    git config --global --add safe.directory /workspace/cpython && \
    if [ -d /workspace/cpython/.git ]; then \
      cd /workspace/cpython && git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt; \
    else \
      : > /opt/lolbench/base_untracked.txt; \
    fi && \
    chown -R agent:agent /workspace/cpython /logs
# Local-reference hardening: remove ensurepip's bundled wheels before replacing
# the fetched history with a parentless baseline.  The pip wheel vendors Tomli,
# which is the implementation requested by this task; deleting only the
# worktree copy would still leave it recoverable through Git objects.
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
    test -z "$unreachable" && \
    chown -R agent:agent .git
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
USER agent
WORKDIR /workspace/cpython
ENV LOLBENCH_INSTANCE_ID=cpython_5
ENV LOLBENCH_SOURCE_SLUG=CPython_PEP-680_tomllib-Support-for-Parsing-TOML-in-the-Standard-Library_PR-31498

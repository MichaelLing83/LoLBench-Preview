# LoLBench eval image: CPython PR-116129 (PEP 696: Type Defaults for Type Parameters)
#   Requirement: https://peps.python.org/pep-0696/
#   base_commit: 852263e1086748492602a90347ecc0a3925e1dda (parent of squash-
#                merge commit ca269e58c290be8ca11bb728004ea842d9f85e3a —
#                see spec.json base_commit_note)
#
# Agent-facing contract (the agent does NOT run anything inside this image;
# the evaluator runs the container after the agent submits a solution.patch):
#
#   docker run --rm \
#       --network=none \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/cpython-pr-116129:1
#
# PEP 696 adds `default=` to type parameters: `class C[T = int]:` /
# `def f[T = int]():` / `type Alias[T = int] = ...`, plus the same
# default= kwarg on typing.TypeVar/ParamSpec/TypeVarTuple. The change
# touches the grammar (Grammar/python.gram, Parser/Python.asdl,
# Parser/parser.c), the AST machinery (Python/ast.c, Python-ast.c,
# pycore_ast*.h), the typing module + C accelerator (Lib/typing.py,
# Modules/_typingmodule.c, Objects/typevarobject.c), and the
# compile/symtable wiring that emits the new SET_FUNCTION_ATTRIBUTE
# intrinsic.
#
# No special capabilities are needed.  The container stays --network=none
# with the default seccomp profile.
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

ARG BASE_COMMIT=852263e1086748492602a90347ecc0a3925e1dda

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

# Pre-build CPython at base_commit. solution.patch touches Grammar/python.gram
# + Parser/Python.asdl, but `make` regenerates the parser tables and Python-ast.c
# from those sources via the standard build rules. No configure.ac /
# Makefile.pre.in / pyconfig.h.in changes — no reconfigure is needed at eval time.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

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
ENV LOLBENCH_INSTANCE_ID=cpython_11
ENV LOLBENCH_SOURCE_SLUG=CPython_PEP-696_Type-Defaults-for-Type-Parameters_PR-116129

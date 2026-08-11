# LoLBench eval image: CPython PR-19503 (PEP 617: New PEG parser for CPython)
#   Requirement: https://peps.python.org/pep-0617/
#   base_commit: a81849b0315277bb3937271174aaaa5059c0b445  (2020-03-20,
#                parent of merge commit c5fc1568 — see spec.json
#                base_commit_note for why this overrides the CSV value)
#
# Agent-facing contract (the agent does NOT run anything inside this image;
# the evaluator runs the container after the agent submits a solution.patch):
#
#   docker run --rm \
#       --network=none \
#       -v $(pwd)/solution.patch:/in/solution.patch:ro \
#       -v $(pwd)/out:/out \
#       lolbench/cpython-pr-19503:1
#
# Unlike the PEP-768 instance, this PR (PEP 617's new PEG parser) does
# NOT need --cap-add=SYS_PTRACE: the new parser runs entirely in-process,
# no cross-process attach. The container stays --network=none with the
# default seccomp profile.
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

ARG BASE_COMMIT=a81849b0315277bb3937271174aaaa5059c0b445

# ---- Per-instance dirs ------------------------------------------------
# /opt/lolbench/private/ holds the eval-side artifacts (eval_tests.patch,
# selectors, golden solution.patch, run_tests.sh).  We keep the path
# name `private` to document intent; perms are default since the
# container is only ever run by the trusted evaluator.
RUN mkdir -p /opt/lolbench/private /in /out /workspace

# ---- Source tree at base_commit ---------------------------------------
# After fetching at the exact base_commit, we reset git history so
# `git log` inside the container does not reveal the SHA (kept for
# tidiness; the evaluator already knows the base, the agent never
# sees the container).
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
# A single full build at base_commit warms the build tree so that
# applying solution.patch at eval time only triggers an incremental
# rebuild (Make handles the dependency graph).  We deliberately do NOT
# pre-apply the patch — the eval/validate dispatcher decides which
# patch to apply per run.
#
# Build flags rationale:
#   --prefix=/usr/local : keep system layout; we use ./python, not the
#                         installed binary, so the install step is omitted
#   --with-pydebug      : OFF (default).  Enabling pydebug doubles test
#                         duration and changes ABI in ways unrelated to
#                         PEP 617.  We build the release configuration.
#   --enable-shared     : OFF (default).  The static interpreter is what
#                         regrtest expects.
#   PEP 617 build       : no extra configure flags; the new PEG parser is
#                         compiled in when Parser/pegen/*.c and
#                         Modules/_peg_parser.c are present (added by
#                         solution.patch).  At pre-state those files are
#                         absent → base build is plain old-parser
#                         CPython 3.9.0a5 from a81849b0.
# `set -o pipefail` so `make ... | tee log` propagates make's non-zero
# exit; otherwise a broken CPython build could ship as a green image
# (the pipeline's exit status would be tee's exit status, which is 0).
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN cd /workspace/cpython && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400

# ---- Eval bundle ------------------------------------------------------
# All eval-side files live in the instance directory root.  The
# Dockerfile bakes them into /opt/lolbench/private/ inside the
# container; the path name is just a stable tooling convention since
# the container runs as root throughout (the agent/evaluator boundary
# is the eval API, not Unix permissions).
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

COPY spec.json \
     solution.patch \
     eval_tests.patch \
     eval_helpers.patch \
     f2p.txt \
     p2p.txt \
     /opt/lolbench/private/
COPY eval_tests_aug.patch \
     f2p_aug.txt \
     p2p_aug.txt \
     /opt/lolbench/private/
COPY run_tests.sh /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_tests.sh

ENTRYPOINT ["/opt/lolbench/private/run_tests.sh"]

# lolbench/cpython-base:1
#
# Layer-2 (project-base) image for all CPython instances.  Ships:
#   - Ubuntu 22.04 + CPython build toolchain (gcc, make, autoconf, …)
#   - All optional-extension headers needed by ./configure for the stdlib
#     modules CPython's test suite expects to be present (ssl, sqlite3,
#     bz2, lzma, readline, ncurses, gdbm, uuid, ffi, etc.).
#
# Layer-3 (per-instance) images do `FROM lolbench/cpython-base:1`, then
# clone python/cpython at the instance's base_commit and build the
# interpreter.
#
# The eval docker is only ever run by a trusted evaluator (an agent never
# executes code inside it), so the image runs everything as root — no
# agent UID, no runuser dance.
#
# Note on CAP_SYS_PTRACE: this image does NOT require any special caps
# at build time.  The per-instance images that exercise PEP 768
# sys.remote_exec (e.g. PR-131937) must be `docker run` with
# `--cap-add=SYS_PTRACE` because Docker's default seccomp profile gates
# process_vm_readv / process_vm_writev behind that capability.  That
# requirement is recorded in each instance's spec.json under
# `docker_run_extra_args`.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Toolchain + every optional-stdlib header CPython 3.13/3.14's
# ./configure looks for.  Omitting any of these makes regrtest skip
# tests that the LoLBench evaluator must actually run (the no-skipped-
# tests rule, see feedback_no_skipped_tests.md).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        autoconf \
        automake \
        ca-certificates \
        curl \
        git \
        make \
        ccache \
        # run_tests.sh's pre-flight checks (spec/selector consistency, JSON
        # I/O for the reports) call /usr/bin/python3 — Ubuntu 22.04's
        # minimal apt set ships python3.10 only as a recommended package,
        # which --no-install-recommends excludes. Pull it in explicitly.
        python3 \
        python3-minimal \
        # CPython optional-stdlib build deps
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libffi-dev \
        libreadline-dev \
        libsqlite3-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        libncursesw5-dev \
        libnsl-dev \
        tk-dev \
        uuid-dev \
        # for sys.remote_exec / process_vm_readv detection at configure time
        libc6-dev \
        # tools used by regrtest / TestRemoteExec helpers
        procps \
    && rm -rf /var/lib/apt/lists/*

# A separate ccache dir keeps incremental rebuilds fast across instances
# of the same toolchain image.
ENV CCACHE_DIR=/root/.ccache \
    PATH=/usr/lib/ccache:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /workspace

ARG BASE_IMAGE=lolbench/cpython-base:1
FROM ${BASE_IMAGE}

ARG BASE_COMMIT=6e8cda91d92da72800d891b2fc2073ecbc134d98

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rm -rf /workspace/cpython && \
    mkdir -p /workspace/cpython /opt/lolbench /logs/artifacts /logs/agent /logs/verifier && \
    if ! id -u agent >/dev/null 2>&1; then useradd -m -s /bin/bash agent; fi

WORKDIR /workspace
RUN git init -q cpython && \
    cd cpython && \
    git remote add origin https://github.com/python/cpython.git && \
    git fetch --no-tags origin ${BASE_COMMIT} && \
    git checkout FETCH_HEAD && \
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
COPY metadata.json /opt/lolbench/metadata.json
COPY lolbench-submit /usr/local/bin/lolbench-submit

WORKDIR /workspace/cpython
RUN chmod +x /usr/local/bin/lolbench-submit && \
    ./configure --prefix=/usr/local --enable-optimizations=no && \
    jobs=$(awk '$1!="max"{printf("%d", ($1+$2-1)/$2)}' /sys/fs/cgroup/cpu.max 2>/dev/null); \
    : "${jobs:=$(nproc)}"; \
    [ "$jobs" -lt 1 ] && jobs=1; \
    make -j"$jobs" 2>&1 | tee /tmp/cpython-build.log | tail -400 && \
    git ls-files --others --exclude-standard | sort > /opt/lolbench/base_untracked.txt && \
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
USER agent
WORKDIR /workspace/cpython

ENV LOLBENCH_INSTANCE_ID=cpython_2
ENV LOLBENCH_SOURCE_SLUG=CPython_PEP-615_Support-for-the-IANA-Time-Zone-Database-in-the-Standard-Library_PR-19909

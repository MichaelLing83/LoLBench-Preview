# LoLBench coverage image: Ruff PR-9599
ARG BASE_IMAGE=lolbench/ruff-pr-9599:1
FROM ${BASE_IMAGE}

RUN rustup component add llvm-tools-preview && \
    cargo install cargo-llvm-cov --locked --version 0.5.36 2>&1 | tail -10

COPY coverage/run_coverage.sh \
     coverage/compute_coverage.py \
     /opt/lolbench/private/
RUN chmod +x /opt/lolbench/private/run_coverage.sh

ENTRYPOINT ["/opt/lolbench/private/run_coverage.sh"]

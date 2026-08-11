# lolbench/fastapi-base-py310:1
# Layer-2 toolchain image for FastAPI PR-4871 (PEP-593 Annotated dependency support).
# Python 3.10 (FastAPI requires-python >= 3.7; the py39 tutorial tests rely on
# PEP-604 union syntax via typing.Optional, but 3.10 covers both 3.7+ and 3.9+ markers).
FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# FastAPI test deps, pinned to what tests/test_annotated.py + tutorials require.
RUN pip install --upgrade pip && \
    pip install \
        "pytest>=7.1.3,<8.0.0" \
        "pytest-json-report>=1.5.0,<2.0.0" \
        "coverage[toml]>=6.5.0,<8.0" \
        "httpx>=0.23.0,<0.24.0" \
        "email_validator>=1.1.1,<2.0.0" \
        "sqlalchemy>=1.3.18,<1.4.43" \
        "peewee>=3.13.3,<4.0.0" \
        "databases[sqlite]>=0.3.2,<0.7.0" \
        "orjson>=3.2.1,<4.0.0" \
        "ujson>=4.0.1,<6.0.0" \
        "python-multipart>=0.0.5,<0.0.7" \
        "flask>=1.1.2,<3.0.0" \
        "anyio[trio]>=3.2.1,<4.0.0" \
        "python-jose[cryptography]>=3.3.0,<4.0.0" \
        "pyyaml>=5.3.1,<7.0.0" \
        "passlib[bcrypt]>=1.7.2,<2.0.0" \
        "typing_extensions>=4.5.0"

WORKDIR /workspace

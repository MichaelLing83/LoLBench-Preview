# lolbench/flink-base-jdk8:1
#
# Layer-2 (project-base) image for Apache-Flink instances whose
# base_commit sits in the Flink 1.x line that targeted JDK 8
# (Flink 1.10 and earlier).  Ships:
#   - eclipse-temurin OpenJDK 8
#   - Apache Maven 3.x (bundled in maven:3-eclipse-temurin-8)
#   - git (bundled)
#   - python3 (copied from python:3.11-slim in stage 1)
#
# We avoid `apt-get install python3` because Docker Desktop's
# in-container DNS resolution for archive.ubuntu.com has been flaky on
# the build host; the multi-stage copy from python:3.11-slim sidesteps
# apt entirely.  This mirrors lolbench/flink-base:1 (JDK 11) — only
# the JDK major version differs.

# Stage 1: pull python:3.11-slim purely as a source of /usr/local/bin/python3.
FROM python:3.11-slim AS pysrc

# Stage 2: real base image.
FROM maven:3-eclipse-temurin-8

# Copy python from the slim image.  We need both the python3 binary and
# its stdlib (in /usr/local/lib/python3.11) plus the shared libs.
COPY --from=pysrc /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=pysrc /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=pysrc /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=pysrc /usr/local/lib/libpython3.11.so.1.0 /usr/local/lib/libpython3.11.so.1.0
RUN ldconfig && python3 --version

ENV MAVEN_OPTS="-Xmx4g -XX:ReservedCodeCacheSize=512m" \
    MVN_OPTS="-B -fae"

WORKDIR /workspace

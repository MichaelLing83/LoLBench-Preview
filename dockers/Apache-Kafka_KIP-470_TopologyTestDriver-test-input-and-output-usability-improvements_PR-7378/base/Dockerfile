# lolbench/kafka-base-jdk8-gradle562:1
#
# Layer-2 toolchain image for Apache-Kafka instances in the 2.4.x line.
# Kafka 2.4 pins Gradle 5.6.2 (gradle/dependencies.gradle) — using a
# different Gradle major version breaks the Scala plugin's compiler
# selection, so we pin exactly.

FROM python:3.11-slim AS pysrc

FROM eclipse-temurin:8-jdk

ARG GRADLE_VERSION=5.6.2
ENV GRADLE_HOME=/opt/gradle \
    PATH=/opt/gradle/bin:$PATH \
    GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false"

RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates unzip curl bash \
    && rm -rf /var/lib/apt/lists/*

COPY --from=pysrc /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=pysrc /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=pysrc /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=pysrc /usr/local/lib/libpython3.11.so.1.0 /usr/local/lib/libpython3.11.so.1.0
RUN ldconfig && python3 --version

RUN set -eux; \
    curl -fsSL -o /tmp/gradle.zip \
        "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"; \
    echo "32fce6628848f799b0ad3205ae8db67d0d828c10ffe62b748a7c0d9f4a5d9ee0 */tmp/gradle.zip" | sha256sum -c -; \
    unzip -q /tmp/gradle.zip -d /opt; \
    mv "/opt/gradle-${GRADLE_VERSION}" /opt/gradle; \
    rm /tmp/gradle.zip; \
    gradle --version

WORKDIR /workspace

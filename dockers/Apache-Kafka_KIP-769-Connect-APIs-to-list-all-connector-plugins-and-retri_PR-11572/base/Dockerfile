# lolbench/kafka-base-jdk11-gradle733:1
# Layer-2 toolchain for Apache-Kafka 3.2.x (Gradle 7.3.3, Scala 2.13.6).
FROM python:3.11-slim AS pysrc
FROM eclipse-temurin:11-jdk

ARG GRADLE_VERSION=7.3.3
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
    echo "b586e04868a22fd817c8971330fec37e298f3242eb85c374181b12d637f80302 */tmp/gradle.zip" | sha256sum -c -; \
    unzip -q /tmp/gradle.zip -d /opt; \
    mv "/opt/gradle-${GRADLE_VERSION}" /opt/gradle; \
    rm /tmp/gradle.zip; \
    gradle --version

WORKDIR /workspace

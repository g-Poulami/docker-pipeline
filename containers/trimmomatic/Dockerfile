# ─────────────────────────────────────────────────────────────────────────────
# Trimmomatic 0.39 — multi-stage build
# ─────────────────────────────────────────────────────────────────────────────

FROM debian:bookworm-slim AS builder

ARG TRIMMOMATIC_VERSION=0.39

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q \
    "http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-${TRIMMOMATIC_VERSION}.zip" \
    -O trimmomatic.zip \
    && unzip trimmomatic.zip \
    && rm trimmomatic.zip

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy

ARG TRIMMOMATIC_VERSION=0.39
LABEL org.opencontainers.image.title="Trimmomatic"
LABEL org.opencontainers.image.version="${TRIMMOMATIC_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/g-Poulami/docker-pipeline"

RUN groupadd -r bioinfo && useradd -r -g bioinfo bioinfo

COPY --from=builder /build/Trimmomatic-${TRIMMOMATIC_VERSION} /opt/trimmomatic

RUN printf '#!/bin/sh\nexec java -jar /opt/trimmomatic/trimmomatic-${TRIMMOMATIC_VERSION}.jar "$@"\n' \
    > /usr/local/bin/trimmomatic \
    && chmod +x /usr/local/bin/trimmomatic

RUN mkdir -p /data/input /data/output && chown -R bioinfo:bioinfo /data

USER bioinfo
WORKDIR /data

ENTRYPOINT ["trimmomatic"]
CMD ["--help"]

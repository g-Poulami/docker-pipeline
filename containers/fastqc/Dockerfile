# ─────────────────────────────────────────────────────────────────────────────
# FastQC 0.12.1 — multi-stage build
# Builder : downloads and unpacks FastQC
# Runtime : minimal JRE only — no wget, no unzip, no build tools
# ─────────────────────────────────────────────────────────────────────────────

FROM debian:bookworm-slim AS builder

ARG FASTQC_VERSION=0.12.1

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q \
    "https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v${FASTQC_VERSION}.zip" \
    -O fastqc.zip \
    && unzip fastqc.zip \
    && chmod +x FastQC/fastqc \
    && rm fastqc.zip

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy

ARG FASTQC_VERSION=0.12.1
LABEL org.opencontainers.image.title="FastQC"
LABEL org.opencontainers.image.version="${FASTQC_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/g-Poulami/docker-pipeline"

RUN groupadd -r bioinfo && useradd -r -g bioinfo bioinfo

COPY --from=builder /build/FastQC /opt/fastqc
RUN apt-get update && apt-get install -y --no-install-recommends \
        perl \
    && rm -rf /var/lib/apt/lists/*
RUN ln -s /opt/fastqc/fastqc /usr/local/bin/fastqc

RUN mkdir -p /data/input /data/output && chown -R bioinfo:bioinfo /data

USER bioinfo
WORKDIR /data

ENTRYPOINT ["fastqc"]
CMD ["--help"]

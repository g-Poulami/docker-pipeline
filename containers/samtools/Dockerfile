# ─────────────────────────────────────────────────────────────────────────────
# SAMtools 1.19 — compiled from source
# ─────────────────────────────────────────────────────────────────────────────

FROM debian:bookworm-slim AS builder

ARG SAMTOOLS_VERSION=1.19

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget make gcc autoconf \
        zlib1g-dev libbz2-dev liblzma-dev \
        libcurl4-openssl-dev libssl-dev libncurses5-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q \
    "https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2" \
    -O samtools.tar.bz2 \
    && tar -xjf samtools.tar.bz2 \
    && cd samtools-${SAMTOOLS_VERSION} \
    && ./configure --prefix=/opt/samtools \
    && make \
    && make install \
    && cd .. \
    && rm -rf samtools.tar.bz2 samtools-${SAMTOOLS_VERSION}

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

ARG SAMTOOLS_VERSION=1.19
LABEL org.opencontainers.image.title="SAMtools"
LABEL org.opencontainers.image.version="${SAMTOOLS_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/g-Poulami/docker-pipeline"

RUN apt-get update && apt-get install -y --no-install-recommends \
        zlib1g libbz2-1.0 liblzma5 libcurl4 libncurses6 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r bioinfo && useradd -r -g bioinfo bioinfo

COPY --from=builder /opt/samtools /opt/samtools
RUN ln -s /opt/samtools/bin/samtools /usr/local/bin/samtools

RUN mkdir -p /data/input /data/output && chown -R bioinfo:bioinfo /data

USER bioinfo
WORKDIR /data

ENTRYPOINT ["samtools"]
CMD ["--help"]

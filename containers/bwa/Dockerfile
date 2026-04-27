# ─────────────────────────────────────────────────────────────────────────────
# BWA 0.7.18 — compiled from source in builder stage
# Runtime image has only the binary and its shared library dependencies
# ─────────────────────────────────────────────────────────────────────────────

FROM debian:bookworm-slim AS builder

ARG BWA_VERSION=0.7.18

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget make gcc zlib1g-dev libbz2-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q \
    "https://github.com/lh3/bwa/archive/refs/tags/v${BWA_VERSION}.tar.gz" \
    -O bwa.tar.gz \
    && tar -xzf bwa.tar.gz \
    && cd bwa-${BWA_VERSION} \
    && make \
    && cp bwa /usr/local/bin/bwa \
    && cd .. \
    && rm -rf bwa.tar.gz bwa-${BWA_VERSION}

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

ARG BWA_VERSION=0.7.18
LABEL org.opencontainers.image.title="BWA"
LABEL org.opencontainers.image.version="${BWA_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/g-Poulami/docker-pipeline"

RUN apt-get update && apt-get install -y --no-install-recommends \
        zlib1g libbz2-1.0 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r bioinfo && useradd -r -g bioinfo bioinfo

COPY --from=builder /usr/local/bin/bwa /usr/local/bin/bwa

RUN mkdir -p /data/input /data/ref /data/output && chown -R bioinfo:bioinfo /data

USER bioinfo
WORKDIR /data

ENTRYPOINT ["bwa"]
CMD ["--help"]

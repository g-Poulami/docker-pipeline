# ─────────────────────────────────────────────────────────────────────────────
# GATK 4.5.0.0
# Wraps the official Broad Institute image with:
#   - Non-root bioinfo user
#   - SAMtools added for faidx and index operations
#   - Convenience wrapper so users call `gatk` not `java -jar gatk.jar`
# ─────────────────────────────────────────────────────────────────────────────

FROM broadinstitute/gatk:4.5.0.0

LABEL org.opencontainers.image.title="GATK"
LABEL org.opencontainers.image.version="4.5.0.0"
LABEL org.opencontainers.image.source="https://github.com/g-Poulami/docker-pipeline"

RUN apt-get update && apt-get install -y --no-install-recommends \
        samtools \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r bioinfo && useradd -r -g bioinfo -G root bioinfo

RUN mkdir -p /data/input /data/ref /data/output \
    && chown -R bioinfo:bioinfo /data

USER bioinfo
WORKDIR /data

ENTRYPOINT ["gatk"]
CMD ["--help"]

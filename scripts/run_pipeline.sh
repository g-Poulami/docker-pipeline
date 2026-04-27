#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_pipeline.sh
#
# Runs the full variant calling pipeline using Docker Compose.
# Each tool runs in its own container. No bioinformatics tools need to be
# installed on the host — only Docker and Docker Compose.
#
# Usage:
#   cp .env.example .env
#   # Edit .env with your paths
#   bash scripts/run_pipeline.sh
#
# Or pass arguments directly:
#   bash scripts/run_pipeline.sh \
#     --reads-dir /path/to/fastq \
#     --r1        SRR062634_R1.fastq.gz \
#     --r2        SRR062634_R2.fastq.gz \
#     --genome-dir /path/to/ref \
#     --genome-file chr22.fa \
#     --sample    SRR062634 \
#     --results   ./results
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --reads-dir)   export READS_DIR="$2";    shift 2 ;;
        --r1)          export R1="$2";            shift 2 ;;
        --r2)          export R2="$2";            shift 2 ;;
        --genome-dir)  export GENOME_DIR="$2";   shift 2 ;;
        --genome-file) export GENOME_FILE="$2";  shift 2 ;;
        --sample)      export SAMPLE="$2";       shift 2 ;;
        --results)     export RESULTS_DIR="$2";  shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Load .env if it exists and args were not passed
if [[ -f .env ]]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Validate required variables
for var in READS_DIR R1 R2 GENOME_DIR GENOME_FILE SAMPLE; do
    if [[ -z "${!var:-}" ]]; then
        echo "ERROR: ${var} is not set. Copy .env.example to .env and fill it in."
        exit 1
    fi
done

RESULTS_DIR="${RESULTS_DIR:-./results}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── Build images ──────────────────────────────────────────────────────────────
log "Building Docker images..."
docker compose build

# ── Create results directory ──────────────────────────────────────────────────
mkdir -p "${RESULTS_DIR}"

# ── Step 1: QC on raw reads ───────────────────────────────────────────────────
log "Step 1: FastQC on raw reads"
docker compose run --rm fastqc_raw

# ── Step 2: Trim adapters ─────────────────────────────────────────────────────
log "Step 2: Trimmomatic"
docker compose run --rm trimmomatic

# ── Step 3: QC on trimmed reads ───────────────────────────────────────────────
log "Step 3: FastQC on trimmed reads"
docker compose run --rm fastqc_trimmed

# ── Step 4: Index reference (skip if already done) ────────────────────────────
if [[ ! -f "${GENOME_DIR}/${GENOME_FILE}.bwt" ]]; then
    log "Step 4: BWA index"
    docker compose run --rm bwa_index
else
    log "Step 4: BWA index already exists, skipping"
fi

# ── Step 5: Prepare reference for GATK ───────────────────────────────────────
if [[ ! -f "${GENOME_DIR}/${GENOME_FILE%.fa}.dict" ]] && \
   [[ ! -f "${GENOME_DIR}/${GENOME_FILE}.dict" ]]; then
    log "Step 5a: GATK CreateSequenceDictionary"
    docker compose run --rm gatk_dict
fi

if [[ ! -f "${GENOME_DIR}/${GENOME_FILE}.fai" ]]; then
    log "Step 5b: SAMtools faidx"
    docker compose run --rm gatk_faidx
fi

# ── Step 6: Align ─────────────────────────────────────────────────────────────
log "Step 6: BWA MEM — aligning reads"
# BWA writes to stdout; redirect into the bam_data volume via a temp container
docker compose run --rm bwa_mem \
    > /tmp/${SAMPLE}.sam

# Copy SAM into the bam_data volume
docker run --rm \
    -v /tmp/${SAMPLE}.sam:/tmp/${SAMPLE}.sam:ro \
    -v docker-pipeline_bam_data:/data/bam \
    debian:bookworm-slim \
    cp /tmp/${SAMPLE}.sam /data/bam/${SAMPLE}.sam

rm -f /tmp/${SAMPLE}.sam

# ── Step 7: Sort and index BAM ────────────────────────────────────────────────
log "Step 7: SAMtools sort"
docker compose run --rm samtools_sort

log "Step 7: SAMtools index"
docker compose run --rm samtools_index

log "Step 7: SAMtools flagstat"
docker compose run --rm samtools_flagstat \
    > "${RESULTS_DIR}/${SAMPLE}.flagstat"

cat "${RESULTS_DIR}/${SAMPLE}.flagstat"

# ── Step 8: GATK HaplotypeCaller ─────────────────────────────────────────────
log "Step 8: GATK HaplotypeCaller"
docker compose run --rm gatk_haplotypecaller

# ── Step 9: Copy results from volumes ────────────────────────────────────────
log "Step 9: Copying results to ${RESULTS_DIR}"
docker run --rm \
    -v docker-pipeline_results_data:/data/results:ro \
    -v "$(realpath ${RESULTS_DIR})":/data/output \
    debian:bookworm-slim \
    cp -r /data/results/. /data/output/

# ── Step 10: MultiQC ─────────────────────────────────────────────────────────
log "Step 10: MultiQC"
docker compose run --rm multiqc

log "Pipeline complete."
log "Results: ${RESULTS_DIR}"
log "MultiQC report: ${RESULTS_DIR}/multiqc/multiqc_report.html"

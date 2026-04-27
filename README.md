# docker-pipeline

A variant calling pipeline orchestrated entirely with Docker Compose.
Each tool runs in its own optimised container. The only requirement on the
host machine is Docker — no BWA, SAMtools, or GATK installation needed.

[![CI](https://github.com/g-Poulami/docker-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/g-Poulami/docker-pipeline/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Pipeline

```
FASTQ reads
     |
     v
FastQC (raw)          per-read quality metrics
     |
     v
Trimmomatic           adapter removal, quality trimming
     |
     v
FastQC (trimmed)      confirm trimming worked
     |
     v
BWA index (once)
     |
BWA MEM               align to reference, embed @RG tag
     |
     v
SAMtools sort         SAM -> coordinate-sorted BAM
SAMtools index        BAI index
SAMtools flagstat     alignment rate, paired stats
     |
     v
GATK HaplotypeCaller  per-sample gVCF variant calls
     |
     v
MultiQC               aggregated HTML report
```

---

## Quick start

### 1. Clone the repo

```bash
git clone https://github.com/g-Poulami/docker-pipeline.git
cd docker-pipeline
```

### 2. Configure your paths

```bash
cp .env.example .env
```

Edit `.env` with your file paths:

```
READS_DIR=/path/to/your/fastq
R1=SRR062634_R1.fastq.gz
R2=SRR062634_R2.fastq.gz
GENOME_DIR=/path/to/ref
GENOME_FILE=chr22.fa
SAMPLE=SRR062634
RESULTS_DIR=./results
```

### 3. Run the pipeline

```bash
bash scripts/run_pipeline.sh
```

Docker will build the images on first run then execute each step in sequence.
Results land in `./results/`.

---

## Running individual steps

Each step can be run independently:

```bash
# Quality control only
docker compose run --rm fastqc_raw

# Check alignment statistics
docker compose run --rm samtools_flagstat

# Re-run variant calling after changing parameters
docker compose run --rm gatk_haplotypecaller
```

---

## Containers

| Container | Base | Build method | Size |
|-----------|------|-------------|------|
| FastQC 0.12.1 | eclipse-temurin:17-jre | Multi-stage, wget + unzip | ~200 MB |
| Trimmomatic 0.39 | eclipse-temurin:17-jre | Multi-stage, wget + unzip | ~200 MB |
| BWA 0.7.18 | debian:bookworm-slim | Multi-stage, compiled from source | ~45 MB |
| SAMtools 1.19 | debian:bookworm-slim | Multi-stage, compiled from source | ~55 MB |
| GATK 4.5.0.0 | broadinstitute/gatk | Extended with non-root user | ~1.8 GB |

All containers run as a non-root `bioinfo` user.

---

## Design decisions

### Why Docker Compose instead of Nextflow?

Nextflow is better for production pipelines with hundreds of samples on HPC clusters. Docker Compose is better for demonstrating container orchestration concepts directly — dependency ordering with `depends_on`, named volumes for data sharing between containers, and environment variable injection from `.env` files. Both approaches have their place.

### Why named volumes instead of bind mounts for intermediate data?

Bind mounts expose intermediate files (SAM files, trimmed FASTQs) on the host filesystem which can accumulate to many gigabytes. Named volumes keep intermediate data inside Docker and are automatically cleaned up with `docker compose down -v`. Only the final results are written to a host directory.

### Why multi-stage builds?

The BWA image is 45 MB with multi-stage builds. Without them it would be over 400 MB because the gcc, make, and header files used to compile BWA would remain in the image. Smaller images pull faster, use less disk, and have a smaller vulnerability surface.

---

## Benchmark image sizes

```bash
docker compose build
bash scripts/benchmark_sizes.sh
```

---

## Project structure

```
docker-pipeline/
├── containers/
│   ├── fastqc/Dockerfile
│   ├── trimmomatic/Dockerfile
│   ├── bwa/Dockerfile
│   ├── samtools/Dockerfile
│   └── gatk/Dockerfile
├── scripts/
│   ├── run_pipeline.sh
│   └── benchmark_sizes.sh
├── docker-compose.yml
├── .env.example
└── .github/
    └── workflows/
        └── ci.yml
```

---

## License

MIT

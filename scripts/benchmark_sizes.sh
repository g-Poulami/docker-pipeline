#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# benchmark_sizes.sh
# Builds each image and prints a size comparison table.
# Run after `docker compose build` to see final image sizes.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

printf "\n%-20s %-15s\n" "Image" "Size (MB)"
printf "%-20s %-15s\n"  "─────" "─────────"

images=(
    "docker-pipeline/fastqc:0.12.1"
    "docker-pipeline/trimmomatic:0.39"
    "docker-pipeline/bwa:0.7.18"
    "docker-pipeline/samtools:1.19"
    "docker-pipeline/gatk:4.5.0.0"
)

for img in "${images[@]}"; do
    size=$(docker image inspect "$img" --format='{{.Size}}' 2>/dev/null \
        | awk '{printf "%.0f", $1/1024/1024}')
    printf "%-20s %-15s\n" "${img##*/}" "${size} MB"
done

echo ""

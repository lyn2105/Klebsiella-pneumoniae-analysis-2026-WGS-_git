#!/bin/bash
#SBATCH --job-name=kp_batch
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=kp_batch_%j.out
#SBATCH --error=kp_batch_%j.err

source ~/.bashrc
conda activate kp_env
set -euo pipefail

THREADS=${SLURM_CPUS_PER_TASK:-8}
REF=/mnt/Users/tbinh_workspace/ThesisDataMGI/reference/Index/kpHS11
IN=/mnt/Users/tbinh_workspace/ThesisDataMGI/02_host_removal/Hostremove20261003

TAG=261005
BAM=bam${TAG}
MOS=mosdepth${TAG}
LOGS=logs${TAG}
MQC=multiqc_report${TAG}

mkdir -p "$BAM" "$MOS" "$LOGS" "$MQC"

echo -e "Sample\tMapping_rate(%)\tAverage_depth(x)\tCoverage_30x(%)" > QC_summary.tsv

for R1 in "$IN"/*_1.fastq.gz; do
    SAMPLE=$(basename "$R1" _1.fastq.gz)
    R2="$IN/${SAMPLE}_2.fastq.gz"

    [[ -f "$R2" ]] || { echo "Thiếu R2 cho $SAMPLE" >&2; continue; }
    echo "Processing $SAMPLE"

    # Mapping -> sorted BAM
    bowtie2 -x "$REF" -1 "$R1" -2 "$R2" -p "$THREADS" 2> "$LOGS/${SAMPLE}.bowtie2.log" |
        samtools sort -@ "$THREADS" -o "$BAM/${SAMPLE}.sorted.bam" -

    samtools index "$BAM/${SAMPLE}.sorted.bam"

    # Mapping rate
    samtools flagstat "$BAM/${SAMPLE}.sorted.bam" > "$LOGS/${SAMPLE}.flagstat.txt"
    MAPPING=$(grep -m1 "mapped (" "$LOGS/${SAMPLE}.flagstat.txt" |
        sed -E 's/.*\(([0-9.]+)%.*/\1/')

    # Coverage
    mosdepth -t "$THREADS" "$MOS/${SAMPLE}" "$BAM/${SAMPLE}.sorted.bam"

    # Average depth (dòng total)
    DEPTH=$(awk '$1=="total" {print $4}' "$MOS/${SAMPLE}.mosdepth.summary.txt")

    # % genome phủ >=30x (dòng total, depth = 30)
    COV30=$(awk '$1=="total" && $2==30 {v=$3*100} END {printf "%.2f", v+0}' \
        "$MOS/${SAMPLE}.mosdepth.global.dist.txt")

    echo -e "${SAMPLE}\t${MAPPING}\t${DEPTH}\t${COV30}" >> QC_summary.tsv
done

multiqc "$LOGS" "$MOS" -o "$MQC"

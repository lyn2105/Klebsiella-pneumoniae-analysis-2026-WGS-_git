#!/bin/bash
#SBATCH --job-name=host_removal
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=host_removal.out
#SBATCH --error=host_removal.err

source ~/.bashrc

# Bowtie2
export PATH="/mnt/Users/tbinh_workspace/ThesisDataMGI/software/bowtie2-2.5.2-linux-x86_64:$PATH"

# Paths
RAWDATA="/mnt/Users/tbinh_workspace/ThesisDataMGI/00_rawdata/Rawdata"
INDEX="/mnt/Users/tbinh_workspace/ThesisDataMGI/reference/Index/hg38_index"

# Output directory
OUTDIR="/mnt/Users/tbinh_workspace/ThesisDataMGI/02_host_removal/Hostremove20261003"
mkdir -p "$OUTDIR"

# Host removal
for R1 in "$RAWDATA"/*_1.fq.gz
do
    SAMPLE=$(basename "$R1" _1.fq.gz)
    R2="$RAWDATA/${SAMPLE}_2.fq.gz"

    OUT_PREFIX="$OUTDIR/nohost_${SAMPLE}"

    echo "========================================"
    echo "Processing: $SAMPLE"
    echo "R1: $R1"
    echo "R2: $R2"
    echo "========================================"

    bowtie2 \
        -x "$INDEX" \
        -1 "$R1" \
        -2 "$R2" \
        --threads 8 \
        --very-sensitive \
        --un-conc-gz "${OUT_PREFIX}_%.fastq.gz" \
        -S /dev/null

    if [ $? -eq 0 ]; then
        echo "Completed: $SAMPLE"
    else
        echo "ERROR: $SAMPLE"
    fi

done

echo "Host removal completed."

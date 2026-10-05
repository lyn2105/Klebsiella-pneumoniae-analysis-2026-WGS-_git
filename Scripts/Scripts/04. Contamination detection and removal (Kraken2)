#!/bin/bash
#SBATCH --job-name=kraken2_filter
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=kraken2.log
#SBATCH --error=kraken2.err

# Input directory (nohost reads)
INPUT_DIR="/mnt/Users/tbinh_workspace/ThesisDataMGI/02_host_removal/nohost"

# Output directory (contamination detection)
OUT_DIR="/mnt/Users/tbinh_workspace/ThesisDataMGI/06_Contamination_detection"
mkdir -p "$OUT_DIR"

# Kraken2 database
DB="/mnt/Suran_database/References/For_WGS/Reference_for_Kraken2/k2_standard_20241228"

cd "$INPUT_DIR" || exit 1

for i in {275..309}
do
    R1="nohost_S250131130_L01_${i}_1.fastq.gz"
    R2="nohost_S250131130_L01_${i}_2.fastq.gz"

    # check file tồn tại
    if [[ ! -f "$R1" || ! -f "$R2" ]]; then
        echo "[SKIP] Sample $i missing files"
        continue
    fi

    echo "[RUN] Sample $i"

    kraken2 \
        --db "$DB" \
        --paired \
        --gzip-compressed \
        --threads 16 \
        --report "$OUT_DIR/S250131130_L01_${i}.report" \
        --output "$OUT_DIR/S250131130_L01_${i}.kraken" \
        "$R1" "$R2"

done

echo "ALL SAMPLES COMPLETED"

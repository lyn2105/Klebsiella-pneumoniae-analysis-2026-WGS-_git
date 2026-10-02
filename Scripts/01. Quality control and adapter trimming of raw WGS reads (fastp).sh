
#!/bin/bash
#SBATCH --job-name=fastp
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=fastp.out
#SBATCH --error=fastp.err

INPUT_DIR="/mnt/Users/tbinh_workspace/ThesisDataMGI/00_rawdata/Rawdata"
OUTPUT_DIR="/mnt/Users/tbinh_workspace/ThesisDataMGI/01_qc/fastp_20260930"

mkdir -p "$OUTPUT_DIR"

cd "$INPUT_DIR" || exit 1

for R1 in *_1.fq.gz
do
    R2=${R1/_1.fq.gz/_2.fq.gz}
    SAMPLE=${R1%_1.fq.gz}

    echo "Processing $SAMPLE"

    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "$OUTPUT_DIR/${SAMPLE}_1_fastp.fq.gz" \
        -O "$OUTPUT_DIR/${SAMPLE}_2_fastp.fq.gz" \
        -h "$OUTPUT_DIR/${SAMPLE}_fastp.html" \
        -j "$OUTPUT_DIR/${SAMPLE}_fastp.json" \
        -w 8  
done

echo "All samples completed."

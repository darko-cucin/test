#!/bin/bash
source /pipeline_scripts/utils.sh

# Parse arguments 
INPUT_DIR=""
SAMPLES=()

ARG_KEYS=(
  "input_dir:INPUT_DIR"
  "samples:SAMPLES[@]"
)

parse_args ARG_KEYS[@] "$@"

# Check if proper parameters/inputs are provided
check_directory_exists "$INPUT_DIR" "--input_dir"
check_accession_numbers "${SAMPLES[@]}"

# Loop through each sample name
for sample in "${SAMPLES[@]}"; do
    echo "Processing sample: $sample"
    
    # Find bam file that contains specified sample 
    files=($(find "$INPUT_DIR/$sample" -type f -name "*$sample.bam*"))

    # Check if files were found for the sample
    if [[ ${#files[@]} -gt 0 ]]; then
        # Generate commands for sammtools to sort and index bam files
        echo "Generating commands for files matching sample: $sample"
        samtools sort $files -o ${INPUT_DIR}/${sample}/${sample}.bam
        samtools index ${INPUT_DIR}/${sample}/${sample}.bam
    else
        echo "No files found for sample: $sample"
    fi
done
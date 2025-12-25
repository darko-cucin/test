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

    # remove bam or bai files if they exist to generate new
    find "$INPUT_DIR/$sample" -type f \( -name "*.bam" -o -name "*.bam.bai" \) -exec rm -f {} \;

    # Find sam file that contains specified sample 
    sam_file=($(find "$INPUT_DIR/$sample" -type f -name "*$sample*.sam"))

    # Check if files were found for the sample
    if [[ ${#sam_file[@]} -gt 0 ]]; then
        # Generate the command for generating bam file from sam file
        echo "Generating commands for files matching sample: $sample"
        samtools view -bS $sam_file > ${INPUT_DIR}/${sample}/${sample}.bam
    else
        echo "No files found for sample: $sample"
    fi
done

#!/bin/bash
source /pipeline_scripts/utils.sh

# Parse arguments 
REFERENCE_GENOME=""
FASTQ_DIR=""
SAMPLES=()
OUTDIR=""

ARG_KEYS=(
  "fastq_directory_name:FASTQ_DIR"
  "samples:SAMPLES[@]"
  "output_directory:OUTDIR"
  "reference_genome_file:REFERENCE_GENOME"
)

parse_args ARG_KEYS[@] "$@"

# Check if proper parameters/inputs are provided
check_directory_exists "$FASTQ_DIR" "fastq_directory_name"
check_accession_numbers "${SAMPLES[@]}"
check_file_exists "$REFERENCE_GENOME" "reference_genome_file"
check_if_parameter_provided "$OUTDIR" "output_directory"

# Loop through each sample name
for sample in "${SAMPLES[@]}"; do
    echo "Processing sample: $sample"
    
    # Find all files that contain the sample name in their filename
    files=($(find "$FASTQ_DIR" -type f -name "*$sample*"))
    mkdir -p "$OUTDIR/$sample"

    # Check if files were found for the sample
    if [[ ${#files[@]} -gt 0 ]]; then
        # Generate the command for the current sample
        echo "Generating commands for files matching sample: $sample"

        # Make lists of sai and fastq files for sample
        sai_files=()
        fastq_files=()
        for file in "${files[@]}"; do
            if [[ "$file" == *.sai ]]; then
                sai_files+=("$file")
            elif [[ "$file" == *.fastq || "$file" == *.fastq.gz || "$file" == *.fq.gz || "$file" == *.fq ]]; then
                fastq_files+=("$file")
            fi
        done

        # Sort the files
        sorted_sai_files=($(echo "${sai_files[@]}" | tr ' ' '\n' | sort))
        sorted_fastq_files=($(echo "${fastq_files[@]}" | tr ' ' '\n' | sort))

        # Combine the sorted groups. It is really imprortant to provide arguments in a specific order for bwa samse and sampe 
        if [[ ${#sorted_sai_files[@]} -eq 1 ]]; then
            bwa samse "$REFERENCE_GENOME" "${sorted_sai_files[@]}" "${sorted_fastq_files[@]}" > "${OUTDIR}/${sample}/${sample}.sam"
        elif [[ ${#sorted_sai_files[@]} -eq 2 ]]; then
            bwa sampe "$REFERENCE_GENOME" "${sorted_sai_files[@]}" "${sorted_fastq_files[@]}" > "${OUTDIR}/${sample}/${sample}.sam"
        fi 
    else
        echo "No files found for sample: $sample"
    fi
done

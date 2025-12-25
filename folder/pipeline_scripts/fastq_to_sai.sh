#!/bin/bash
source /pipeline_scripts/utils.sh

# Parse arguments 
REFERENCE_GENOME=""
FASTQ_DIR=""
ACC_NUMBERS=()

ARG_KEYS=(
  "fastq_directory_name:FASTQ_DIR"
  "accession_numbers:ACC_NUMBERS[@]"
  "reference_genome_file:REFERENCE_GENOME"
)

parse_args ARG_KEYS[@] "$@"

# Check if proper parameters/inputs are provided
check_directory_exists "$FASTQ_DIR" "fastq_directory_name"
check_accession_numbers "${ACC_NUMBERS[@]}"
check_file_exists "$REFERENCE_GENOME" "reference_genome_file"

# Specify reference genome directory
REFERENCE_GENOME_DIRECTORY="${REFERENCE_GENOME%/*}"

# Specify index suffixes 
INDEX_SUFFIXES=("bwt" "sa" "amb" "ann" "pac")
INDEX_FOUND=false

for ext in "${INDEX_SUFFIXES[@]}"; do
    if ls "$REFERENCE_GENOME_DIRECTORY"/*."$ext" 1> /dev/null 2>&1; then
        INDEX_FOUND=true
        break
    fi
done

# Check if index files are found. If they are found just skip indexing
if [ "$INDEX_FOUND" = true ]; then
    echo "Index files already exist. Skipping indexing."
else
    echo "No index files found. Running bwa index..."
    bwa index "$REFERENCE_GENOME"
fi

# Create the sai directory
mkdir -p "$FASTQ_DIR/sai"
shopt -s nullglob  # As we will provide more globs and only one will be matched it will prevent errors from not matching other flobs

# Iterate over each fastq file in the specified directory
for acc in "${ACC_NUMBERS[@]}"; do
    echo "Processing accession number: $acc"

    # Find all FASTQ files for the accession number. Although SRA contains only fastq files this script can be used also for other possible extensions
    fastq_files=("$FASTQ_DIR"/"$acc"*.fastq "$FASTQ_DIR"/"$acc"*.fastq.gz "$FASTQ_DIR"/"$acc"*.fq "$FASTQ_DIR"/"$acc"*.fq.gz)

    if [ ${#fastq_files[@]} -eq 0 ]; then
        echo "No FASTQ files found for accession number: $acc"
        continue
    fi

    # Initialize variables
    R1_FILE=""
    R2_FILE=""
    SE_FILE=""

    # Identify _1 and _2 files. Although SRA contains only fastq files with _1 or _2 suffixes this script can be used also for other possible suffixes (_R1 or _)
    for file in "${fastq_files[@]}"; do
        filename=$(basename "$file")
        if [[ "$filename" =~ (_1|_R1) ]]; then
            R1_FILE="$file"
        elif [[ "$filename" =~ (_2|_R2) ]]; then
            R2_FILE="$file"
        else
            SE_FILE="$file"
        fi
    done

    # Determine if paired-end or single-end
    if [[ -n "$R1_FILE" && -n "$R2_FILE" ]]; then
        # Paired-end
        echo "Paired-end data detected for $acc"
        bwa aln "$REFERENCE_GENOME" "$R1_FILE" > "$FASTQ_DIR/sai/${acc}_1.sai"
        bwa aln "$REFERENCE_GENOME" "$R2_FILE" > "$FASTQ_DIR/sai/${acc}_2.sai"
    else
        # Single-end
        echo "Assuming single-end data for $acc"
        bwa aln "$REFERENCE_GENOME" "$SE_FILE" > "$FASTQ_DIR/sai/${acc}.sai"
    fi
done
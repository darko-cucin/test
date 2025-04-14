#!/bin/bash

source /pipeline_scripts/utils.sh

# Parse arguments
FASTQ_DIR=""
ACC_NUMBERS=()

ARG_KEYS=(
  "fastq_directory_name:FASTQ_DIR"
  "accession_numbers:ACC_NUMBERS[@]"
)

parse_args ARG_KEYS[@] "$@"

# Check if proper parameters/inputs are provided

check_if_parameter_provided "$FASTQ_DIR" "fastq_directory_name"
check_accession_numbers "${ACC_NUMBERS[@]}"

# Make directory where fastq files will be stored. The directory will be named according --fastq_directory_name
mkdir -p "$FASTQ_DIR"

# Loop through all accession numbers
for ACC in "${ACC_NUMBERS[@]}"; do
    echo "Downloading FASTQ for accession: $ACC"

    # Construct SRA fastq FTP prefix

    PREFIX=${ACC:0:6}
    BASE_URL="https://ftp.sra.ebi.ac.uk/vol1/fastq/${PREFIX}/${ACC}"

    # Check the length of the accession number (it can has length 10 and 11) and cd to directory where files for this ID are detected
    if [[ ${#ACC} -eq 10 ]]; then
        SUBDIR="00${ACC: -1}"
    elif [[ ${#ACC} -eq 11 ]]; then
        SUBDIR="0${ACC: -2}"
    fi

    BASE_URL="https://ftp.sra.ebi.ac.uk/vol1/fastq/${PREFIX}/${SUBDIR}/${ACC}"

    # Specifying R1 and R2 URLs. Here we are sure that _1.fastq.gz is the suffix and extension as all files from SRA are named in this way
    # In case that these are random read files we would check for the extension (fastq.gz, fastq, .fq, .fq.gz)
    R1_URL="${BASE_URL}/${ACC}_1.fastq.gz"
    R2_URL="${BASE_URL}/${ACC}_2.fastq.gz"

    if ls "$FASTQ_DIR" | grep -qE "^${ACC}([._])"; then
        echo "File for accession number $ACC already exists. Skipping download for this accession."
        continue  # If this accession number exists just skip downloading again
    fi

    # check for paired end
    if curl --head --silent --fail "$R1_URL" > /dev/null; then
        echo "Paired-end data detected"
        wget -q -P "$FASTQ_DIR" "$R1_URL"
        wget -q -P "$FASTQ_DIR" "$R2_URL"
    else
        # check single-end
        SE_URL="${BASE_URL}/${ACC}.fastq.gz"

        if curl --head --silent --fail "$SE_URL" > /dev/null; then
            echo "Single-end data detected"
            wget -q -P "$FASTQ_DIR" "$SE_URL"
        else
            echo "Failed to find FASTQ files for $ACC". The accession number does not exist.
            exit 1
        fi
    fi
done

echo "Done downloading all samples"
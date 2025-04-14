#!/bin/bash

source /pipeline_scripts/utils.sh

# Parse arguments
REFERENCE_GENOME=""
FASTQ_DIR=""
FASTQ_DIR_LOCAL=""
ACC_NUMBERS=()
OUTPUT_DIR=""
OUTPUT_DIR_LOCAL=""

ARG_KEYS=(
  "reference_genome_file:REFERENCE_GENOME" 
  "fastq_directory_name:FASTQ_DIR"
  "fastq_local_directory_name:FASTQ_DIR_LOCAL"
  "accession_numbers:ACC_NUMBERS[@]"
  "output_directory:OUTPUT_DIR"
  "output_local_directory:OUTPUT_DIR_LOCAL"
)

parse_args ARG_KEYS[@] "$@"

# Check if proper parameters/inputs are provided
check_if_parameter_provided "$FASTQ_DIR" "fastq_directory_name"
check_if_parameter_provided "$FASTQ_DIR_LOCAL" "fastq_local_directory_name"
check_accession_numbers "${ACC_NUMBERS[@]}"
check_if_parameter_provided "$OUTPUT_DIR" "output_directory"
check_if_parameter_provided "$OUTPUT_DIR_LOCAL" "output_local_directory"
check_if_parameter_provided "$REFERENCE_GENOME" "reference_genome_file"

echo "Directory where fastq files will be stored:" "$current_dir/$FASTQ_DIR"
echo "Directory where the input files will be stored:" "$current_dir/$OUTPUT_DIR"
echo "Reference genome file:" "$current_dir/$REFERENCE_GENOME"
echo "Samples that will be processed:" "${ACC_NUMBERS[@]}"

current_dir=$(pwd)

# Log file of the whole pipeline
WHOLE_LOG_FILE=$current_dir/"../opt/logfile.log"
exec > >(tee -a "$WHOLE_LOG_FILE") 2>&1

# Log file for checking the successfull execution per sample
LOG_FILE=$current_dir/"log.txt"
#just fill log file with this in case that all samples are OK
echo "empty" >> $LOG_FILE

for SAMPLE in "${ACC_NUMBERS[@]}"; do
    echo "==> Processing sample: $SAMPLE"

    # If any of the data can't be downloaded just stop the execution
    bash download_data.sh --fastq_directory_name "$FASTQ_DIR" --accession_numbers "$SAMPLE"
    if [ $? -ne 0 ]; then
        echo "download_data.sh failed"
        exit 1
    fi

    bash fastq_to_sai.sh --fastq_directory_name "$FASTQ_DIR" --reference_genome_file "$REFERENCE_GENOME" --accession_numbers "$SAMPLE"
    if [ $? -ne 0 ]; then
        echo "fastq_to_sai.sh failed for $SAMPLE, skipping this sample." >> $LOG_FILE
        continue
    fi

    bash sai_to_sam.sh --fastq_directory_name "$FASTQ_DIR" --output_directory "$OUTPUT_DIR" --samples "$SAMPLE" --reference_genome_file "$REFERENCE_GENOME"
    if [ $? -ne 0 ]; then
        echo "sai_to_sam.sh failed for $SAMPLE, skipping this sample." >> $LOG_FILE
        continue
    fi

    bash sam_to_bam.sh --input_dir "$OUTPUT_DIR" --samples "$SAMPLE"
    if [ $? -ne 0 ]; then
        echo "sam_to_bam.sh failed for $SAMPLE, skipping this sample." >> $LOG_FILE
        continue
    fi

    bash bam_sort_index.sh --input_dir "$OUTPUT_DIR" --samples "$SAMPLE"
    if [ $? -ne 0 ]; then
        echo "bam_sort_index.sh failed for $SAMPLE." >> $LOG_FILE
        continue
    fi

    if grep -q "$SAMPLE" $LOG_FILE; then
        echo ""
    else
        echo "Sample $SAMPLE completed successfully."
    fi

done

echo "Generating sample status report..."
python3 report.py "$FASTQ_DIR" "$OUTPUT_DIR" "$FASTQ_DIR_LOCAL" "$OUTPUT_DIR_LOCAL" "$LOG_FILE" "${ACC_NUMBERS[@]}"
if [ $? -ne 0 ]; then
    echo "Error in generate_status_csv.py. Exiting."
    exit 1
fi

# The last check if all processes finished successfully
if grep -q "failed" $LOG_FILE; then
    echo "Finished with errors. Please check the report.csv file"
else
    echo "All steps completed successfully!"
fi

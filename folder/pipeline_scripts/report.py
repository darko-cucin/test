#!/usr/bin/env python3

import os
import sys
import csv
import glob

def parse_args():
    """Function which parses the arguments"""
    if len(sys.argv) < 7:
        print('Usage: report.py <fastq_directory> <output_directory> <fastq_local_directory> <output_local_directory> <log_file> <sample1> [<sample2> ...]')
        sys.exit(1)

    # Load arguments 
    fastq_dir = os.path.abspath(sys.argv[1])
    output_dir = os.path.abspath(sys.argv[2])
    fastq_dir_local = os.path.abspath(sys.argv[3])
    output_dir_local = os.path.abspath(sys.argv[4])
    log_file = os.path.abspath(sys.argv[5])
    samples = sys.argv[6:]

    return fastq_dir, output_dir, fastq_dir_local, output_dir_local, log_file, samples

def get_failed_samples(log_file, samples):
    """Function which get information about samples that are not processes succesfully in the pipeline"""
    with open(log_file, 'r') as f:
        log_content = f.read()
    # Check if log file contains samples that are processes. If it contains then the processing of the specific sample encountered an issue    
    return [sample for sample in samples if sample in log_content]


def get_local_fastq_paths(fastq_dir, fastq_dir_local, sample):
    """Function which will paths to the local directory for fastq files instead of docker container directory"""

            # Remap paths (from docker to local)
    search_pattern = os.path.join(fastq_dir, f"*{sample}*")
    matching_fastqs = glob.glob(search_pattern)
    local_fastq_paths = [file.replace(fastq_dir, fastq_dir_local) for file in matching_fastqs]
            
            # Just format the way how paths will be shown (if it is paired end data the paths will be ; separated for the same sample)
    if len(local_fastq_paths) == 2:
        local_fastq_paths = ';'.join(local_fastq_paths)
        return local_fastq_paths
    elif len(local_fastq_paths) == 1:
        return local_fastq_paths[0]
    else:
        return "There are not files for this sample"

def write_status_report(output_path, samples, fastq_dir, output_dir, fastq_dir_local, output_dir_local, failed_samples):
    """Function which writes the report csv file"""

    # It will write the final file
    with open(output_path, mode='w', newline='') as csvfile:
        colnames = ['input', 'output', 'status']
        writer = csv.DictWriter(csvfile, fieldnames=colnames)
        writer.writeheader()

        for sample in samples:
            input_path = get_local_fastq_paths(fastq_dir, fastq_dir_local, sample)
            output_path = os.path.join(output_dir, sample)
            local_output_path = output_path.replace(output_dir, output_dir_local)
            status = 'ERR' if sample in failed_samples else 'OK'

            writer.writerow({
                'input': input_path,
                'output': local_output_path,
                'status': status
            })

def main():
    fastq_dir, output_dir, fastq_dir_local, output_dir_local, log_file, samples = parse_args()
    failed_samples = get_failed_samples(log_file, samples)
    status_file = os.path.join(output_dir, 'report.csv')
    write_status_report(status_file, samples, fastq_dir, output_dir, fastq_dir_local, output_dir_local, failed_samples)
    print(f'Status report generated at: {status_file}')

if __name__ == '__main__':
    main()
# because image is build from arm architecture based machine # --platform need to be specified
FROM ubuntu:24.04

LABEL description="Dockerfile for pipeline which processes fastq files to bam files" \
maintainer="Darko Cucin, Velsera, <cucindarko51@gmail.com>"

# turning off the interactive mode to prevent python installation prompting to select geographic area
ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    bwa \
    samtools \
    python3 \
    python3-pip \
    curl \
    wget \
    && apt-get clean

# Add scripts from pipeline scripts directory at your machine to pipeline_scripts directory in docker. If you want you can specify other name for 
# Directory where your scripts are located locally
COPY pipeline_scripts/ /pipeline_scripts/
WORKDIR /pipeline_scripts

# Ensure the script is executable
RUN chmod +x /pipeline_scripts/run_pipeline.sh

# Set the Bash script as the entrypoint
ENTRYPOINT ["/pipeline_scripts/run_pipeline.sh"]

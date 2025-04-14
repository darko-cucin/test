# README.MD 

### Bioinformatics dummy pipeline (from fastq to bam files)

## The structure

The pipeline consists of the multiple steps executed by following scripts:
* **download_data.sh** - This script downloads read data from [SRA Database](https://ftp.sra.ebi.ac.uk/vol1/fastq/) for the specified samples;
* **fastq_to_sai.sh** - This script makes **indices** (if it is not created) and **SAI** files from fastq files by using **bwa** toolkit.
* **sai_to_sam.sh** - This script will convert **SAI** to **SAM** file by using **bwa** toolkit.
* **sam_to_bam.sh** - This script will convert **SAM** to **BAM** file by using **samtools** toolkit.
* **bam_sort_index.sh** - This script will sort and index **BAM** file by using **samtools** toolkit.
* **report.py** - This script will make **report.csv** file which contains information about input and output files as well as about the processing status (OK or ERR).
* **utils.sh** - This script defines some functions that are used in other scripts

The **run_pipeline.sh** script will run the above-mentioned scripts sequentially and per sample. 

## Parameters

These are the parameters which are used for running this script. All of them are mandatory:
* **--fastq_directory_name** - The name of the directory in docker container where read files will be downloaded
* **--fastq_local_directory_name** - The name of the local directory where read files will be transferred from docker container. The directory has to be already created.
* **--accession_numbers** - Accession numbers from SRA which will be used to download corresponding fastq files. Also this parameters specifies sample name.
* **--output_directory** - The name of directory in docker container where output files (**SAM**, **BAM**, **BAI** files) will be downloaded.
* **--output_local_directory** - The name of local directory where output files (**SAM**, **BAM**, **BAI** files) will be transfered from docker container. The directory has to be already created.
* **--reference_genome_file** - The name of reference genome file which will be used to aling read files. The directory has to be already created.

## How to run a pipeline

The pipeline should be run in a docker container which will be run by dockerimage.

Steps to run pipeline:
* 1. Locate into the directory where is **Dockerfile**. Run the following command **docker build -t . <name_of_image>**. Name of image refers to the image that will be created (e.g **username/fastq_to_bam_pipeline**). It is not advisable to change pipeline_scripts directory as input scripts will be copied from there. If you change the name of directory where scripts are located this should be changed also in the docker file.
* 2. Run the docker image. Run the following command ```docker run -v <Path to local directory with reference genome file>:/<Path to docker directory where reference genome file will be located> -v <Path to local directory where input files will be transfered>:/<Path to docker directory where input files will be downloaded> -v /<Path to local directory where output files will be transfered>:/<Path to docker directory where output files will be generated> --fastq_directory_name combined_se_pe_final_fastq --accession_numbers SRR1010320 SRR25800099 --output_directory combined_se_pe_final --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/darko/Desktop/Epam/input_from_docker --output_local_directory /Users/darko/Desktop/Epam/output_from_docker```

## Test data

We have provided you a couple of read files derived from **SRA**. They are located at the **test_data** directory. If you already have input files the downloading step will be skipped. As reference genome files are quite large we could not be able to store them at the **GitHub**. If you wanty to download data for the specific organism refer to [Ensembl downloads](https://www.ensembl.org/info/data/ftp/index.html)


## Examples of running a pipeline

The examples for different use cases:

* 1. Single single end sample - ```docker run -v /Users/darko/Desktop/Epam/reference_genome/homo_sapiens/:/reference_genome/ -v /Users/user/pipeline/single_end_local_input:/pipeline_scripts/single_end_input/ -v /Users/user/pipeline/single_end_local_output:/pipeline_scripts/single_end_output/ darkocucin/fastq_to_bam_pipeline --fastq_directory_name single_end_input --accession_numbers SRR1010320 --output_directory single_end_output --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/user/pipeline/single_end_local_input --output_local_directory /Users/user/pipeline/single_end_local_output```

* 2. Single paired-end sample - ```docker run -v /Users/user/pipeline/reference_genome/homo_sapiens/:/reference_genome/ -v /Users/user/pipeline/paired_end_local_input:/pipeline_scripts/paired_end_input/ -v /Users/user/pipeline/single_end_local_output:/pipeline_scripts/paired_end_output/ darkocucin/fastq_to_bam_pipeline --fastq_directory_name paired_end_input --accession_numbers SRR25800099 --output_directory paired_end_output --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/user/pipeline/paired_end_local_input --output_local_directory /Users/darko/Desktop/Epam/paired_end_local_output```

* 3. Combined single end paired-end - ```docker run -v /Users/user/pipeline/reference_genome/homo_sapiens/:/reference_genome/ -v /Users/user/pipeline/combined_se_pe_final_local_fastqs:/pipeline_scripts/combined_se_pe_final_fastqs/ -v /Users/user/pipeline/combined_se_pe_final_local_output:/pipeline_scripts/combined_se_pe_final/ darkocucin/fastq_to_bam_pipeline --fastq_directory_name combined_se_pe_final_fastq --accession_numbers SRR1010320 SRR25800099 --output_directory combined_se_pe_final --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/user/pipeline/combined_se_pe_final_local_fastqs --output_local_directory /Users/user/pipeline/combined_se_pe_final_local_output```
 
* 4. Multiple paired-end samples - ```docker run -v /Users/user/pipeline/reference_genome/homo_sapiens/:/reference_genome/ -v /Users/darko/Desktop/Epam/paired_end_multiple_local_input:/pipeline_scripts/paired_end_multiple_input/ -v /Users/user/pipeline/paired_end_multiple_local_output:/pipeline_scripts/paired_end_multiple_output/ darkocucin/fastq_to_bam_pipeline --fastq_directory_name single_end_input --accession_numbers SRR25800099 --output_directory paired_end_multiple_output --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/user/pipeline/paired_end_multiple_local_input --output_local_directory /Users/user/pipeline/paired_end_multiple_local_output```
 
* 5. Multiple single-end samples - ```docker run -v /Users/user/pipeline/reference_genome/homo_sapiens/:/reference_genome/ -v /Users/user/pipeline/single_end_multiple_local_input:/pipeline_scripts/single_end_multiple_input/ -v /Users/user/pipeline/Epam/single_end_multiple_local_output:/pipeline_scripts/single_end_multiple_output/ darkocucin/fastq_to_bam_pipeline --fastq_directory_name single_end_input --accession_numbers SRR1010320 SRR1001445 --output_directory paired_end_multiple_output --reference_genome_file ../reference_genome/Homo_sapiens.GRCh38.dna_sm.chromosome.1.fa.gz --fastq_local_directory_name /Users/user/pipeline/single_end_multiple_local_input --output_local_directory /Users/user/pipeline/single_end_multiple_local_output```

If you want to mount log file from the complete pipeline exectuion just add ```-v </Path to the local directory where logfile will be stored>:/opt/``` - opt is directory where the logfile is generated in the docker. E.g ```-v /files/logfiles/single_end/:/opt/```

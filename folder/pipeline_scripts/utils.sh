#!/bin/bash

# Functions

check_directory_exists() {
    local dir_value="$1"     # The actual value (may be empty)
    local arg_name="$2"      # The flag name (e.g., fastq_directory_name)

    if [[ -z "$dir_value" ]]; then
        echo "Error: --$arg_name argument is required."
        exit 1
    elif [[ ! -d "$dir_value" ]]; then
        echo "Error: Directory for --$arg_name ('$dir_value') does not exist."
        exit 1
    fi
}

check_file_exists() {
  local file_value="$1"     # The actual value (may be empty)
  local arg_name="$2"      # The flag name (e.g., reference_genome_file)
  if [ ! -f "$1" ]; then
    echo "Error: File for --$arg_name ('$file_value') does not exist."
    exit 1
  fi
}

check_if_parameter_provided() {
  local string_value="$1"     # The actual value (may be empty)
  local arg_name="$2"      # The flag name (e.g., output_directory_name)

  if [[ -z "$1" ]]; then
    echo "Error: --$arg_name argument is required."
    exit 1
  fi
}

check_accession_numbers() {
  if [[ "$#" -eq 0 ]]; then
    echo "Error: --accession_numbers argument is required and must include at least one value."
    exit 1
  fi
}

#!/bin/bash

# Format: ARG_KEYS=("fastq_directory_name:FASTQ_DIR" "accession_numbers:ACC_NUMBERS[@]")
parse_args() {
    local -a arg_keys=("${!1}")
    shift

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            # This will print all arguments that are required (it would be good also to add description of parameters)
            --help)
                echo "Usage: $0 with options:"
                for item in "${arg_keys[@]}"; do
                    echo "  --${item%%:*}"
                done
                exit 0
                ;;
            --*)
            # Assign values of the argument
                local key="${1/--/}"
                local var=""
                for item in "${arg_keys[@]}"; do
                    if [[ "$item" == "$key:"* ]]; then
                        var="${item#*:}"
                        break
                    fi
                done
                
                # Check if value is found for the argument
                if [[ -z "$var" ]]; then
                    echo "Unknown argument: --$key"
                    exit 1
                fi

                shift

                # Checks if argument should be treated as an array
                if [[ "$var" == *"[@]" ]]; then
                    local name="${var%\[@\]}"
                    while [[ "$#" -gt 0 && "$1" != --* ]]; do
                        eval "$name+=(\"\$1\")"
                        shift
                    done
                else
                    if [[ "$#" -eq 0 || "$1" == --* ]]; then
                        echo "Error: Missing value for --$key"
                        exit 1
                    fi
                    eval "$var=\"\$1\""
                    shift
                fi
                ;;
            *)
                echo "Unknown parameter: $1"
                exit 1
                ;;
        esac
    done
}


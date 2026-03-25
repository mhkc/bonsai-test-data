#!/usr/bin/env bash

# Build JASEN input CSV from ENA metadata TSV

set -euo pipefail

DEFAULT_OUTDIR="$(dirname "$0")/../data/jasen_input"

usage() {
    cat <<EOF
Usage: $0 -i <ena.tsv> -f <fastq_dir> [-o <outdir>]

Options:
  -i FILE   Path to ENA metadata TSV (must contain "fastq_ftp" column)
  -f DIR    Directory containing downloaded FASTQ files
  -o DIR    Output directory for JASEN input (default: $DEFAULT_OUTDIR)
  -h        Show this help message
EOF
    exit 1
}

input=""
fastqdir=""
outdir="$DEFAULT_OUTDIR"

# argparse-like loop
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) input="$2"; shift 2 ;;
        -f) fastqdir="$2"; shift 2 ;;
        -o) outdir="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$input" ]] && { echo "Error: -i <input.tsv> is required" >&2; exit 1; }
[[ ! -f "$input" ]] && { echo "Error: file '$input' not found" >&2; exit 1; }

[[ -z "$fastqdir" ]] && { echo "Error: -f <fastq_dir> is required" >&2; exit 1; }
[[ ! -d "$fastqdir" ]] && { echo "Error: directory '$fastqdir' not found" >&2; exit 1; }

# Convert fastqdir to absolute path
fastqdir=$(realpath "$fastqdir")

# ensure output directory exists
mkdir -p "$outdir"

# Detect platform from input filename (e.g., project.illumina.tsv or project.ont.tsv)
filename=$(basename "$input")
if [[ ! "$filename" =~ \.(illumina|ont)\.tsv$ ]]; then
    echo "Error: Input filename must match pattern: <project>.(illumina|ont).tsv" >&2
    exit 1
fi

platform_input="${BASH_REMATCH[1]}"

# Normalize platform name for output
case "$platform_input" in
    illumina) platform="illumina" ;;
    ont) platform="nanopore" ;;
    *) echo "Error: Unknown platform '$platform_input'" >&2; exit 1 ;;
esac

# Create output filename based on input (e.g., PRJEB77209.illumina.csv)
output_base="${filename%.tsv}.csv"
output_file="$outdir/$output_base"

# Write CSV header based on platform
if [[ "$platform_input" == "illumina" ]]; then
    echo "id,platform,sequencing_run,read1,read2" > "$output_file"
else
    echo "id,platform,sequencing_run,read1" > "$output_file"
fi

sample_count=$(awk 'NR>1 && NF' "$input" | wc -l)
echo "Found $sample_count sample(s). Building JASEN input in: $output_file"

# read and build JASEN input
awk -F'\t' 'NR > 1 && NF' "$input" | while IFS=$'\t' read -r run study sample exp sci title fastq_ftp sample_title; do
    IFS=';' read -ra urls <<< "$fastq_ftp"

    if [[ "$platform_input" == "illumina" ]]; then
        # For Illumina, expect exactly 2 reads
        if [[ ${#urls[@]} -lt 2 ]]; then
            echo "Warning: Expected 2 reads for Illumina, got ${#urls[@]} for run $run" >&2
            continue
        fi
        
        # Construct full paths to downloaded files
        read1_path=$(realpath "$fastqdir/$(basename "${urls[0]}")")
        read2_path=$(realpath "$fastqdir/$(basename "${urls[1]}")")

        echo "$run,$platform,$run,$read1_path,$read2_path" >> "$output_file"
    else
        # For ONT/Nanopore, expect 1 read
        if [[ ${#urls[@]} -lt 1 ]]; then
            echo "Warning: Expected 1 read for ONT, got ${#urls[@]} for run $run" >&2
            continue
        fi
        
        # Construct full path to downloaded file
        read1_path=$(realpath "$fastqdir/$(basename "${urls[0]}")")
        
        echo "$run,$platform,$run,$read1_path" >> "$output_file"
    fi
done

echo "Done."
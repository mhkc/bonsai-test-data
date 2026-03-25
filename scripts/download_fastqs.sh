#!/usr/bin/env bash

# ENA fastq downloader with defaults and safety improvements

set -euo pipefail

DEFAULT_OUTDIR="$(dirname "$0")/../data/fastq"

usage() {
    cat <<EOF
Usage: $0 [-i <ena.tsv>] [-o <outdir>] [--dry-run]

Options:
  -i FILE   Path to ENA metadata TSV (must contain "fastq_ftp" column)
  -o DIR    Output directory for FASTQs (default: $DEFAULT_OUTDIR)
  --dry-run Print download actions but do not download
  -h        Show this help message
EOF
    exit 1
}

input=""
outdir="$DEFAULT_OUTDIR"
dry_run=false

# argparse-like loop
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) input="$2"; shift 2 ;;
        -o) outdir="$2"; shift 2 ;;
        --dry-run) dry_run=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[[ -z "$input" ]] && { echo "Error: -i <input.tsv> is required" >&2; exit 1; }
[[ ! -f "$input" ]] && { echo "Error: file '$input' not found" >&2; exit 1; }

# ensure output directory exists
mkdir -p "$outdir"

# validate column exists
if ! head -1 "$input" | grep -q "fastq_ftp"; then
    echo "Error: TSV missing expected 'fastq_ftp' column" >&2
    exit 1
fi

sample_count=$(awk 'NR>1 && NF' "$input" | wc -l)
echo "Found $sample_count sample(s). Downloading to: $outdir"

# read and download
awk -F'\t' 'NR > 1 && NF' "$input" | while IFS=$'\t' read -r run study sample exp sci title fastq_ftp sample_title; do
    IFS=';' read -ra urls <<< "$fastq_ftp"

    for url in "${urls[@]}"; do
        [[ -z "$url" ]] && continue
        local_url="http://$url"

        echo "→ $local_url"

        if [[ "$dry_run" = false ]]; then
            wget -c --tries=5 --timeout=20 -P "$outdir" "$local_url"
        fi
    done
done

echo "Download complete."
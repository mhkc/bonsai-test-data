# Bonsai Test Data

## Overview

This repository contains curated test dataset for Bonsai.

It is intended to support:

- Local development environments
- Integration and end-to-end testing
- Demo instances
- PRP‑driven sample uploads
- Database seeding during bootstrap

This repo is not part of any single microservice.
It serves as a shared, versioned source of truth for reproducible Bonsai test environments.

##  Docker Init Container

This repository also provides a Docker image that Bonsai environments use to mount test data.

### Build locally

```sh
docker build -t bonsai-test-data:local .
```

### Usage in Docker Compose (Dev/E2E)

```yaml
init-test-data:
  image: ghcr.io/clinicalgenomicslund/bonsai-test-data:v0.1.0
  volumes:
    - testdata:/mnt/testdata
  command: ["sh", "-c", "cp -r /dataset/* /mnt/testdata"]
```

## Reanalyze datasets

Updates to [JASEN](https://github.com/genomic-medicine-sweden/jasen) can require the test data to be reanalyzed. Here are the steps to redownload the data and recompute the results.

**Note** See JASEN docs for installation instructions and how to run it.

Download the datasets if needed.

```sh
./scripts/download_fastqs.sh -i bioprojects/PRJEB77209.illumina.tsv
```

Create a JASEN input file using the path to the downloaded fastq files.

```sh
./scripts/make_jasen_input.sh              \
    -i bioprojects/PRJEB77209.illumina.tsv \
    -f /path/to/fastq/                     \
    -o /output/dir/
```

Then run JASEN to produce the output files.

**NOTE: You have to add and assay column using the SMD convenience start_nextflow_analysis to run JASEN.**

```sh
nextflow run main.nf                                      \
        -profile staphylococcus_aureus,illumina,apptainer \
        -config nextflow.config                           \
        --csv /output/dir/PRJEB77209.illumina.csv
```

Copy the files to the repo as either a new pipline version or overwrite existing result.

```sh
# if relevant change the version of jasen
jasen_version=1.2.0
resultPath=/fs1/results_dev/jasen/saureus
targetDir="/path/to/repo/results/v${jasen_version}/saureus"

# find all new result files
mkdir -p $targetDir
tail -n +2 PRJEB77209.illumina.csv | awk -F',' '{print $1}' | while read -r id; do
  cd "$resultPath"
  find . -name "${id}*" -exec echo cp -R --parents {} "$targetDir" \;
done
```

Finally subset large BAM files to reduce repo size.

```sh
find ${targetDir} -name "*.bam" -exec samtools view -b -s 0.05 {} > {} \;
```
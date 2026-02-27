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

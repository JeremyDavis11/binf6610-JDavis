#!/bin/bash
#SBATCH -A binf6610.202710 -p courses
#SBATCH -c 4 --mem=16G -t 00:30:00
#SBATCH -o pull-%j.out
set -euo pipefail
export APPTAINER_CACHEDIR=/scratch/${USER}/apptainer-cache
mkdir -p /scratch/${USER}/containers
apptainer pull /scratch/${USER}/containers/variant-call.sif \
    docker://jeremydavis11/variant-call@sha256:3130d0c70496314058779f89996a6cc7fc51860d98e6a1b4e72d1d75eaacf8a0

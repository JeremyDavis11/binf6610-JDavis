#!/usr/bin/env bash
set -euo pipefail
source conf/slurm.env

for c in 4 8 16; do
    rm -rf "${RUN_ROOT}/run"
    sbatch --wait -c "$c" --array=1-1 -p courses -A binf6610.202710 01_persample.sbatch
done
sacct -u $USER --format=JobID,JobName,AllocCPUS,Elapsed,MaxRSS,State --starttime today > core_comparison.txt



#!/bin/bash
#SBATCH --job-name=w2-cohort
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/cohort_%j.out
#SBATCH --export=NONE
#-----------------------------------------------------------------------------
# Stages 6-9, once, after every array task has succeeded.
# set SBATCH values after testing
#-----------------------------------------------------------------------------
set -euo pipefail

if [[ ! -s "${SLURM_SUBMIT_DIR}/conf/slurm.env" ]]; then
    printf 'no conf/slurm.env in %s\n' "${SLURM_SUBMIT_DIR}" >&2
    printf 'submit from the slurm/ directory, or use: bash submit.sh\n' >&2
    exit 78            # EX_CONFIG
fi
source "${SLURM_SUBMIT_DIR}/conf/slurm.env"

module load miniconda3/25.9.1
source activate "${CONDA_ENV}"

export THREADS="${SLURM_CPUS_PER_TASK}"
export REF_DIR FASTQ_ROOT
export TMPDIR="/tmp/${SLURM_JOB_ID}"
mkdir -p "${TMPDIR}"
trap 'rm -rf "${TMPDIR}"' EXIT

echo "cohort on $(hostname), ${SLURM_CPUS_PER_TASK} cores"
bash "${PIPELINE_DIR}/run_pipeline.sh" "${SHEET}" "${RUN_ROOT}/run" publish

# The results are small and must outlive the /scratch purge. The BAMs are not
# and stay where they are.
mkdir -p "${KEEP_DIR}"
cp -r "${RUN_ROOT}/run/results" "${KEEP_DIR}/results-${SLURM_JOB_ID}"
echo "kept: ${KEEP_DIR}/results-${SLURM_JOB_ID}"
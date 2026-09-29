#!/bin/bash
#SBATCH --job-name=w3-persample
#SBATCH --array=1-8
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=00:20:00
#SBATCH --output=logs/persample_%A_%a.out
#SBATCH --export=NONE
#-----------------------------------------------------------------------------
# Stages 0-5 for ONE sample. Twelve of these run at the same time.
# change SBATCH values to suit my pipeline
#-----------------------------------------------------------------------------
set -euo pipefail


if [[ ! -s "${SLURM_SUBMIT_DIR}/conf/slurm.env" ]]; then
    printf 'no conf/slurm.env in %s\n' "${SLURM_SUBMIT_DIR}" >&2
    printf 'submit from the slurm/ directory, or use: bash submit.sh\n' >&2
    exit 78            # EX_CONFIG
fi
source "${SLURM_SUBMIT_DIR}/conf/slurm.env"

# The threads Slurm actually gave us, handed to the tools. The pipeline already
# reads THREADS from the environment, so this is the whole change.
export THREADS="${SLURM_CPUS_PER_TASK}"
export REF_DIR FASTQ_ROOT REGION

# Scratch on the node's own disk, and a trap that removes it however this job
# ends. /tmp here is shared with every other job on the node, and a `rm` at the
# bottom of the script does not run when the job is cancelled or times out.
export TMPDIR="/tmp/${SLURM_JOB_ID}"
mkdir -p "${TMPDIR}"
trap 'rm -rf "${TMPDIR}"' EXIT

# One task is one sample. The scheduler picks WHICH; run_sample.sh does the work.
SAMPLE=$(awk -F, -v n="${SLURM_ARRAY_TASK_ID}" 'NR == n + 1 { print $1 }' "${SHEET}")

# An array wider than the samplesheet gets an empty name here, and a pipeline
# handed nothing succeeds at every stage. Refuse instead.
[[ -n "${SAMPLE}" ]] || { echo "task ${SLURM_ARRAY_TASK_ID}: no row ${SLURM_ARRAY_TASK_ID} in ${SHEET}" >&2; exit 64; }

echo "task ${SLURM_ARRAY_TASK_ID} on $(hostname): ${SAMPLE}, ${SLURM_CPUS_PER_TASK} cores"
apptainer exec --cleanenv \
    --env THREADS="${THREADS}" \
    --env TMPDIR="${TMPDIR}" \
    --env SLURM_JOB_ID="${SLURM_JOB_ID}" \
    --env SLURM_CPUS_PER_TASK="${SLURM_CPUS_PER_TASK}" \
    --env REF_DIR="${REF_DIR}" \
    --env FASTQ_ROOT="${FASTQ_ROOT}" \
    --env REGION="${REGION}" \
    --env PLATFORM_KIND="${PLATFORM_KIND}" \
    --env IMPLEMENTATION="${IMPLEMENTATION}" \
    --bind /courses/BINF6610.202710,/scratch/${USER} \
    "${SIF}" \
    bash "${PIPELINE_DIR}/run_sample.sh" "${SHEET}" "${RUN_ROOT}/run" "${SAMPLE}" quantify

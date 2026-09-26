#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

SHEET=${1:?usage: ...}
OUT=${2:?usage: ...}
LAST=${3:-publish}
SAMPLE=""

source "${HERE}/lib/common.sh"
setup_dirs
for f in "${HERE}"/stages/*.sh; do source "$f"; done

STAGES=(validate qc_raw trim align postprocess quantify merge analyze qc_report publish)

known=0
for stage in "${STAGES[@]}"; do
    [[ "$stage" == "$LAST" ]] && known=1
done
(( known )) || die "unknown stage: ${LAST}"

n=0
for stage in "${STAGES[@]}"; do
    log "===== stage ${n} : ${stage} ====="
    "stage_${stage}"
    [[ "$stage" == "$LAST" ]] && break
    n=$(( n + 1 ))
done
log "pipeline done"
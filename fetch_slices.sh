#!bin/bash/dev 

set -euo pipefail

stage_fetch() {
    local id run lt r1 r2 r1_url r2_url

    while IFS=, read -r id run lt r1 r2; do
        if [[ ! -s "$r1" ]]; then
            log "$id: fetching R1"
            r1_url=$(curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${run}&result=read_run&fields=fastq_ftp" | tail -n +2 | cut -f2 | tr '$
            curl -fs "https://${r1_url}" | gzip -dc | head -"$SLICE_LINES" | gzip > "$r1" || true # head closes the pipe, so curl and gzip exit non-zero even $
        fi
        if [[ "$lt" == paired && ! -s "$r2" ]]; then
                log "$id: fetching R2"
                r2_url=$(curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${run}&result=read_run&fields=fastq_ftp" | tail -n +2 | cut -f2 | $
                curl -fs "https://${r2_url}" | gzip -dc | head -"$SLICE_LINES" | gzip > "$r2" || true # head closes the pipe, so curl and gzip exit non-zero e$
         fi

    done < <(tail -n +2 "$SHEET")
}

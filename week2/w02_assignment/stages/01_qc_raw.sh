# shellcheck shell=bash
# stage 01 - get quality control metrics for each sample

stage_qc_raw() {
    local id cond rep lt r1 r2 base

    while IFS=, read -r id cond rep lt r1 r2; do
        
        # define basename and resume guard - week 2 addition
        base=$(basename "$r1" .fastq.gz)
        if [[ -s  "${QC}/${base}_fastqc.zip" ]]; then log "$id: qc already done"; continue; fi

        log "$id: fastqc"
        fastqc -q -o "$QC" -t "$THREADS" "$r1" 2> "${LOG}/${id}.fastqc.log"
        if [[ "$lt" == paired ]]; then
            fastqc -q -o "$QC" -t "$THREADS" "$r2" 2>> "${LOG}/${id}.fastqc.log"
        fi
	
	# ask disk if fastqc wrote anything
	[[ -s "${QC}/${base}_fastqc.zip" ]] || die "$id: fastqc produced no report"
	log "$id: qc done"

    done < <(rows "$SHEET" "$SAMPLE")
}


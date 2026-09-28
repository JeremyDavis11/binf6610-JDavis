# shellcheck shell=bash
# 02 - trim adaptors and low quality reads

stage_trim() {
        local id cond rep lt r1 r2 n
        while IFS=, read -r id cond rep lt r1 r2; do

        # resume guard - week 2 addition
        if [[ -s "${TRIM}/${id}_R1.trim.fastq.gz" ]]; then log "$id: trim already done"; continue; fi

        if [[ "$lt" == paired ]]; then
                fastp -w "$THREADS" -i "$r1" -I "$r2" \
                -o "${TRIM}/${id}_R1.trim.fastq.gz" -O "${TRIM}/${id}_R2.trim.fastq.gz" \
		-j "${LOG}/${id}.fastp.json" -h "${LOG}/${id}.fastp.html" \
		2> "${LOG}/${id}.fastp.log"
	else
		fastp -w "$THREADS" -i "$r1" -o "${TRIM}/${id}_R1.trim.fastq.gz" \
                  -j "${LOG}/${id}.fastp.json" -h "${LOG}/${id}.fastp.html" \
                  2> "${LOG}/${id}.fastp.log"
	fi

	# trimming removes reads. Zero reads left means something went wrong
	n=$(gzip -dc "${TRIM}/${id}_R1.trim.fastq.gz" | wc -l)
        (( n > 0 )) || die "$id: nothing survived trimming"
        log "$id: trimmed to $(( n / 4 )) reads"
    done < <(rows "$SHEET" "$SAMPLE")
}

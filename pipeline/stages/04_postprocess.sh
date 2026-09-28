# shellcheck shell=bash
# 4 · postprocess BAM files

stage_postprocess() {
	local id cond rep lt r1 r2 sort_tmp
	while IFS=, read -r id cond rep lt r1 r2; do
        # resume guard
        if [[ -s "${ALN}/${id}.markdup.bam.bai" ]]; then log "$id: postprocess already done"; continue; fi

        # intermediate BAM files go in TMP
        sort_tmp="${TMPDIR:-/tmp}/sort.${id}.$$"
		samtools sort -@ "$SORT_THREADS" -T "$sort_tmp" -o "${ALN}/${id}.sorted.bam" "${ALN}/${id}.bam"
		gatk MarkDuplicates -I "${ALN}/${id}.sorted.bam" -O "${ALN}/${id}.markdup.bam" -M "${LOG}/${id}.markdup.metrics.txt" > "${LOG}/${id}.gatk.log" 2>&1
		samtools index -@ "$SORT_THREADS" "${ALN}/${id}.markdup.bam"
		[[ -s "${ALN}/${id}.markdup.bam" ]] || die "$id: MarkDuplicates produced no BAM"
		[[ -s "${ALN}/${id}.markdup.bam.bai" ]] || die "$id: no index for markdup BAM"
        samtools flagstat -@ "$SORT_THREADS" "${ALN}/${id}.markdup.bam" > "${LOG}/${id}.flagstat.txt"
		log "$id: sorted, indexed, and duplicate marked"
	done < <(rows "$SHEET" "$SAMPLE")
}

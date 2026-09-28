# shellcheck shell=bash
# 03 - align into a BAM file

stage_align() {
	local id cond rep lt r1 r2 rg rate
	while IFS=, read -r id cond rep lt r1 r2; do

        # resume guard
        if [[ -s "${ALN}/${id}.bam" ]]; then log "$id: align already done"; continue; fi

		rg="@RG\tID:${id}\tSM:${id}\tLB:${id}\tPL:ILLUMINA\tPU:${id}"
		if [[ "$lt" == paired ]]; then
			bwa mem -t "$THREADS" -R "$rg" "$INDEX" "${TRIM}/${id}_R1.trim.fastq.gz" "${TRIM}/${id}_R2.trim.fastq.gz" 2> "${LOG}/${id}.bwamem.log"
		else
			bwa mem -t "$THREADS" -R "$rg" "$INDEX" "${TRIM}/${id}_R1.trim.fastq.gz" 2> "${LOG}/${id}.bwamem.log"
		fi | samtools view -b -o "${ALN}/${id}.bam.tmp"
        # move fully writtem final BAM from TMP to output directory
        mv "${ALN}/${id}.bam.tmp" "${ALN}/${id}.bam"
        
		rate=$(samtools flagstat "${ALN}/${id}.bam" | awk '/0 mapped \(/ { gsub(/[(%]/, "", $5); print $5 }')
		log "$id: ${rate}% aligned"
		awk -v r="$rate" 'BEGIN { exit !(r > 10) }' || die "$id: alignment rate ${rate}% - wrong ref or mates are mixed up"

	done < <(rows "$SHEET" "$SAMPLE")
}
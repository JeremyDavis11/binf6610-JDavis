# shellcheck shell=bash
# 05 - quantify variants into a GVCF file 

stage_quantify() {
	local id cond rep lt r1 r2
	while IFS=, read -r id cond rep lt r1 r2; do

        # resume guard - guard on the .tbi because it is the last thing haplotypecaller produces
         if [[ -s "${GVCF}/${id}.g.vcf.gz.tbi" ]]; then log "$id: quantify already done"; continue; fi

		gatk HaplotypeCaller -R "$FASTA" -I "${ALN}/${id}.markdup.bam" -O "${GVCF}/${id}.g.vcf.gz" -ERC GVCF --tmp-dir "${TMPDIR:-/tmp}" > "${LOG}/${id}.hc.log" 2>&1
		[[ -s "${GVCF}/${id}.g.vcf.gz.tbi" ]] || die "$id: HaplotypeCaller produced no GVCF"
		log "$id: HaplotypeCaller produced a GVCF"
		done < <(rows "$SHEET" "$SAMPLE")
}
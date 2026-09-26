# shellcheck shell=bash
# 06 - merge individual GVCFs into a sinlge cohort VCF

stage_merge() {
	local id cond rep lt r1 r2 n expected vargs=""
	while IFS=, read -r id cond rep lt r1 r2; do
		vargs="${vargs} -V ${GVCF}/${id}.g.vcf.gz"
	done < <(rows "$SHEET")
	
	rm -rf "${OUT}/genomicsdb" # GATK refuses to write into an existing workspace so a re-run fails without this	
	gatk GenomicsDBImport $vargs --genomicsdb-workspace-path "${OUT}/genomicsdb"  -L "$REGION" > "${LOG}/genomicsdbimport.log" 2>&1
	gatk GenotypeGVCFs -R "$FASTA" -V "gendb://${OUT}/genomicsdb" -O "${RES}/cohort.vcf.gz" > "${LOG}/genotypegvcfs.log" 2>&1
	
	# verify
	[[ -s "${RES}/cohort.vcf.gz" ]] || die "no cohort vcf generated"
	n=$(gzip -dc "${RES}/cohort.vcf.gz" | grep '^#CHROM' | awk '{ print NF - 9 }')
	expected=$(rows "$SHEET" | wc -l)
	(( n == expected )) || die "cohort VCF has $n samples, expected $expected"
}

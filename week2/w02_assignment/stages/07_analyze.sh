# shellcheck shell=bash
# 07 - variant filtration and analysis
# omitting VCF annotation for now per TA Canvas discussion on 9/18/2026.

stage_analyze() {

    gatk VariantFiltration -R "$FASTA" \
	-V "${RES}/cohort.vcf.gz" \
	-O "${RES}/cohort.filtered.vcf.gz" \
	--filter-name "QD2" --filter-expression "QD < 2.0" \
	>"${LOG}/VariantFiltration.log" 2>&1 || die "VariantFiltration failed — see ${LOG}/VariantFiltration.log"
	
    [[ -s "${RES}/cohort.filtered.vcf.gz" ]] || die "analyze produced no filtered VCF"
    log "filtered VCF: $(gzip -dc "${RES}/cohort.filtered.vcf.gz" | grep -c 'QD2') variants flagged"
}

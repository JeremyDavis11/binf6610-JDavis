# shellcheck shell=bash
# 08 - MultiQC reports

stage_qc_report() {
	multiqc "$OUT" -o "$RES" > "${LOG}/multiqc.log" 2>&1 || die "MultiQC failed. see ${LOG}/multiqc.log"
	[[ -d "${RES}/multiqc_data" ]] || die "multiqc wrote no data directory"
    [[ -s "${RES}/multiqc_report.html" ]] || die "multiqc produced no report"
	log "qc_report generated"
}
# shellcheck shell=bash
# 09 - publish what this pipeline produced in a readable file

stage_publish() {
	local samples_json metrics_json reads outputs_json st ty pa sum entry n sep id cond rep lt r1 r2 git_sha finished_at run_id
    # generate tsv
    {   
	    printf 'run_started\t%s\n'  "$STARTED_AT"
        printf 'run_finished\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'samplesheet\t%s\n'  "$SHEET"
        printf 'reference\t%s\n'    "$FASTA"
        printf 'git_commit\t%s\n'   "$(git -C "$PIPE_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
        printf 'bwa\t%s\n'          "$(bwa 2>&1 | grep -i version | head -1)"
        printf 'samtools\t%s\n'     "$(samtools --version | head -1)"
        printf 'fastp\t%s\n'        "$(fastp --version 2>&1 | head -1)"
        printf 'gatk\t%s\n'         "$(gatk --version 2>&1 | head -1)"
        printf 'host\t%s\n'         "$(hostname)"
        printf 'slurm_job_id\t%s\n' "${SLURM_JOB_ID:-none}"
        printf 'slurm_cpus\t%s\n'   "${SLURM_CPUS_PER_TASK:-none}"
        printf 'threads\t%s\n'      "$THREADS"
    } > "${DB}/run_info.tsv"
    
	# populate samples file
	samples_json=""
	sep=""
	while IFS=, read -r id cond rep lt r1 r2; do
    		samples_json="${samples_json}${sep}{\"sample_id\":\"${id}\",\"library_type\":\"${lt}\",\"condition\":\"${cond}\"}"
    		sep=","
        done < <(rows "$SHEET")
	# populate metrics file
    metrics_json=""
	sep=""
    while IFS=, read -r id cond rep lt r1 r2; do
			n=$(gzip -dc "${TRIM}/${id}_R1.trim.fastq.gz" | wc -l)
        	reads=$(( n / 4 ))
            metrics_json="${metrics_json}${sep}{\"sample_id\":\"${id}\",\"metric\":\"reads_after_trim\",\"value\":${reads},\"unit\":\"count\",\"stage\":\"trim\"}"
			sep=","
    done < <(rows "$SHEET")
	# publish files
	outputs_json=""
	sep=""
	for entry in \
		"merge|cohort_vcf|cohort.vcf.gz" \
		"analyze|filtered_vcf|cohort.filtered.vcf.gz" \
		"qc_report|multiqc|multiqc_report.html" \
		"publish|run_info|db/run_info.tsv"
	do
		IFS='|' read -r st ty pa <<< "$entry"
		sum=$(sha256_of "${RES}/${pa}")
		outputs_json="${outputs_json}${sep}{\"stage\":\"${st}\",\"type\":\"${ty}\",\"path\":\"${pa}\",\"checksum\":\"sha256:${sum}\"}"
		sep=","
	done
	
	# publish heredoc
	git_sha=$(git -C "$PIPE_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)
	finished_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	run_id="${finished_at}-$$"

	cat > "${RES}/manifest.json" << EOF
	{
		"pipeline": {
			"name": "variant-call",
			"version": "1.0.0",
			"implementation": "${IMPLEMENTATION}",
			"git_sha": "${git_sha}",
			"run_id": "${run_id}",
			"started_at": "${STARTED_AT}",
			"finished_at": "${finished_at}",
			"exit_status": "success"
			},
			"platform": { "kind": "${PLATFORM_KIND}" },
			"reference": { "genome": "GRCh38_full_analysis_set_plus_decoy_hla" },
			"samples": [ ${samples_json} ],
			"outputs": [ ${outputs_json} ],
			"metrics": [ ${metrics_json} ] 
		}
EOF
log "results in ${RES}:"
ls -1 "$RES" >&2
}	

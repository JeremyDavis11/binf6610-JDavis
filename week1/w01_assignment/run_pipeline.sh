#!/usr/bin/env bash

set -euo pipefail

# mark start time
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# samplesheet
SHEET=${1:?usage: run_pipeline.sh <samplesheet.csv> <outdir> [last-stage]}
OUT=${2:?usage: run_pipeline.sh <samplesheet.csv> <outdir> [last-stage]}
LAST=${3:-publish}

# config
REF_DIR=${REF_DIR:-data/refs/grch38}
THREADS=${THREADS:-4}
FASTA=${REF:-${FASTA:-${REF_DIR}/chr20.fa}}
REGION=${REGION:-chr20}
INDEX=${INDEX:-${FASTA}}
DEV=${DEV:-dev}
SLICE_LINES=${SLICE_LINES:-16000}

QC="${OUT}/qc_raw"; TRIM="${OUT}/trim"; ALN="${OUT}/align"
GVCF="${OUT}/GVCF"; LOG="${OUT}/logs"; RES="${OUT}/results"
DB="${RES}/db"
mkdir -p "$QC" "$TRIM" "$ALN" "$GVCF" "$LOG" "$RES" "$DB"

# helper functions
log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 65; }

# stages in order
STAGES=(validate qc_raw trim align postprocess quantify merge analyze qc_report publish)

# catch a typo in the third argument before running anything
known=0
for stage in "${STAGES[@]}"; do
	[[ "$stage" == "$LAST" ]] && known=1
done
(( known )) || die "unknown stage: ${LAST}"

#=============================================================================
# 0 · validate — check everything before computing anything
#=============================================================================

stage_validate() {
	local id cond rep lt r1 r2 n1 n2 problems=0
	
	while IFS=, read -r id cond rep lt r1 r2; do
		[[ -n "$id" ]] || { log "a row has no sample_id"; problems=$(( problems + 1 )); continue; }
	
		# the files exist and are non-empty
	 	[[ -s "$r1" ]] || { log "$id: R1 missing or empty: $r1"; problems=$(( problems + 1 )); }
        	if [[ "$lt" == paired ]]; then
            	[[ -s "$r2" ]] || { log "$id: declared paired but R2 is missing"; problems=$(( problems + 1 )); }
        	fi

		# the r2 column and the declared layout agree
	 	if [[ -z "$r2" && "$lt" == paired ]]; then
            	log "$id: r2_fastq is empty but library_type says paired"
            	problems=$(( problems + 1 ))
       		fi
	
		# the gzip streams are whole
		 [[ ! -s "$r1" ]] || gzip -t "$r1" 2>/dev/null || { log "$id: R1 is not a valid gzip file"; problems=$(( problems + 1 )); }

    		 # the records are whole, and the mates agree
       		 if [[ -s "$r1" ]]; then
           		 n1=$(gzip -dc "$r1" | wc -l)
            		(( n1 % 4 == 0 )) || { log "$id: R1 has $n1 lines, not a whole number of records"
                                  		 problems=$(( problems + 1 )); }
           		 if [[ "$lt" == paired && -s "$r2" ]]; then
               			 n2=$(gzip -dc "$r2" | wc -l)
               			 (( n1 == n2 )) || { log "$id: R1 has $(( n1 / 4 )) reads, R2 has $(( n2 / 4 ))"
                                   	 problems=$(( problems + 1 )); }
            	fi
       	fi
    	done < <(tail -n +2 "$SHEET")

    # duplicate sample ids. sort | uniq -d prints only the repeats.
    local dupes
    dupes=$(awk -F, 'NR>1 { print $1 }' "$SHEET" | sort | uniq -d)
    [[ -z "$dupes" ]] || { log "duplicate sample_id: $dupes"; problems=$(( problems + 1 )); }
    
    # the reference is where the config says it is
    [[ -s "$FASTA" ]] || { log "no FASTA at ${FASTA}"; problems=$(( problems + 1 )); }
    [[ -s "${INDEX}.bwt" ]]           || { log "no BWA index at ${INDEX}";     problems=$(( problems + 1 )); }
    [[ -s "${FASTA}.fai" ]]     || { log "no .fai at ${FASTA}.fai"; problems=$(( problems + 1 )); }
    [[ -s "${FASTA%.fa}.dict" ]] || { log "no .dict at ${FASTA%.fa}.dict"; problems=$(( problems + 1 )); }

    (( problems == 0 )) || die "validation failed with ${problems} problem(s)"
    log "validation passed"

}

#=============================================================================
# 1 · qc_raw — FastQC on the reads as they arrive
#=============================================================================

stage_qc_raw() {
    local id cond rep lt r1 r2 base

    while IFS=, read -r id cond rep lt r1 r2; do
        log "$id: fastqc"
        fastqc -q -o "$QC" -t "$THREADS" "$r1" 2> "${LOG}/${id}.fastqc.log"
        if [[ "$lt" == paired ]]; then
            fastqc -q -o "$QC" -t "$THREADS" "$r2" 2>> "${LOG}/${id}.fastqc.log"
        fi
	
	# ask disk if fastqc wrote anything
	base=$(basename "$r1" .fastq.gz)
	[[ -s "${QC}/${base}_fastqc.zip" ]] || die "$id: fastqc produced no report"
	log "$id: qc done"

    done < <(tail -n +2 "$SHEET")
}

#=============================================================================
# 2 · trim — adapters and low-quality tails
#=============================================================================
stage_trim() {
        local id cond rep lt r1 r2 n
        while IFS=, read -r id cond rep lt r1 r2; do
        if [[ "$lt" == paired ]]; then
                fastp -i "$r1" -I "$r2" \
                -o "${TRIM}/${id}_R1.trim.fastq.gz" -O "${TRIM}/${id}_R2.trim.fastq.gz" \
		-j "${LOG}/${id}.fastp.json" -h "${LOG}/${id}.fastp.html" \
		2> "${LOG}/${id}.fastp.log"
	else
		fastp -i "$r1" -o "${TRIM}/${id}_R1.trim.fastq.gz" \
                  -j "${LOG}/${id}.fastp.json" -h "${LOG}/${id}.fastp.html" \
                  2> "${LOG}/${id}.fastp.log"
	fi

	# trimming removes reads. Zero reads left means something went wrong
	n=$(gzip -dc "${TRIM}/${id}_R1.trim.fastq.gz" | wc -l)
        (( n > 0 )) || die "$id: nothing survived trimming"
        log "$id: trimmed to $(( n / 4 )) reads"
    done < <(tail -n +2 "$SHEET")
}

#=============================================================================
# 3 · align — align to the whole GRCh38
#=============================================================================

stage_align() {
	local id cond rep lt r1 r2 rg rate
	while IFS=, read -r id cond rep lt r1 r2; do
		rg="@RG\tID:${id}\tSM:${id}\tLB:${id}\tPL:ILLUMINA\tPU:${id}"
		if [[ "$lt" == paired ]]; then
			bwa mem -t "$THREADS" -R "$rg" "$INDEX" "${TRIM}/${id}_R1.trim.fastq.gz" "${TRIM}/${id}_R2.trim.fastq.gz" 2> "${LOG}/${id}.bwamem.log"
		else
			bwa mem -t "$THREADS" -R "$rg" "$INDEX" "${TRIM}/${id}_R1.trim.fastq.gz" 2> "${LOG}/${id}.bwamem.log"
		fi | samtools view -b -o "${ALN}/${id}.bam"
		rate=$(samtools flagstat "${ALN}/${id}.bam" | awk '/0 mapped \(/ { gsub(/[(%]/, "", $5); print $5 }')
		log "$id: ${rate}% aligned"
		awk -v r="$rate" 'BEGIN { exit !(r > 10) }' || die "$id: alignment rate ${rate}% - wrong ref or mates are mixed up"
	done < <(tail -n +2 "$SHEET")
}

#=============================================================================
# 4 · postprocess — sort, index, and mark duplicates with samtools and GATK
#=============================================================================

stage_postprocess() {
	local id cond rep lt r1 r2
	while IFS=, read -r id cond rep lt r1 r2; do
		samtools sort -o "${ALN}/${id}.sorted.bam" "${ALN}/${id}.bam"
		gatk MarkDuplicates -I "${ALN}/${id}.sorted.bam" -O "${ALN}/${id}.markdup.bam" -M "${LOG}/${id}.markdup.metrics.txt" > "${LOG}/${id}.gatk.log" 2>&1
		samtools index "${ALN}/${id}.markdup.bam"
		[[ -s "${ALN}/${id}.markdup.bam" ]] || die "$id: MarkDuplicates produced no BAM"
		[[ -s "${ALN}/${id}.markdup.bam.bai" ]] || die "$id: no index for markdup BAM"
		log "$id: sorted, indexed, and duplicate marked"
	done < <(tail -n +2 "$SHEET")
}

#=============================================================================
# 5 · quantify — per-sample variant calling into a GVCF
#=============================================================================

stage_quantify() {
	local id cond rep lt r1 r2
	while IFS=, read -r id cond rep lt r1 r2; do
		gatk HaplotypeCaller -R "$FASTA" -I "${ALN}/${id}.markdup.bam" -O "${GVCF}/${id}.g.vcf.gz" -ERC GVCF > "${LOG}/${id}.hc.log" 2>&1
		[[ -s "${GVCF}/${id}.g.vcf.gz" ]] || die "$id: HaplotypeCaller produced no GVCF"
		log "$id: HaplotypeCaller produced a GVF"
		done < <(tail -n +2 "$SHEET")
}

#=============================================================================
# 6 · merge — joint genotyping of all samples
#=============================================================================

stage_merge() {
	local id cond rep lt r1 r2 n expected vargs=""
	while IFS=, read -r id cond rep lt r1 r2; do
		vargs="${vargs} -V ${GVCF}/${id}.g.vcf.gz"
	done < <(tail -n +2 "$SHEET")
	
	rm -rf "${OUT}/genomicsdb" # GATK refuses to write into an existing workspace so a re-run fails without this	
	gatk GenomicsDBImport $vargs --genomicsdb-workspace-path "${OUT}/genomicsdb"  -L "$REGION" > "${LOG}/genomicsdbimport.log" 2>&1
	gatk GenotypeGVCFs -R "$FASTA" -V "gendb://${OUT}/genomicsdb" -O "${RES}/cohort.vcf.gz" > "${LOG}/genotypegvcfs.log" 2>&1
	
	# verify
	[[ -s "${RES}/cohort.vcf.gz" ]] || die "no cohort vcf generated"
	n=$(gzip -dc "${RES}/cohort.vcf.gz" | grep '^#CHROM' | awk '{ print NF - 9 }')
	expected=$(tail -n +2 "$SHEET" | wc -l)
	(( n == expected )) || die "cohort VCF has $n samples, expected $expected"
}

#=============================================================================
# 7 · analyze — GATK VariantFiltration and annotation
#=============================================================================

stage_analyze() {
    gatk VariantFiltration -R "$FASTA" \
	-V "${RES}/cohort.vcf.gz" \
	-O "${RES}/cohort.filtered.vcf.gz" \
	--filter-name "QD2" --filter-expression "QD < 2.0" \
	>"${LOG}/VariantFiltration.log" 2>&1
	
    [[ -s "${RES}/cohort.filtered.vcf.gz" ]] || die "VariantFiltration produced no VCF"
    log "analyze: filtered VCF written"
}
# omitting VCF annotation for now per TA discussion on Canvas.

#=============================================================================
# 8 · qc_report — MultiQC for one report across the cohort
#=============================================================================

stage_qc_report () {
	multiqc "$OUT" -o "$RES" > "${LOG}/multiqc.log" 2>&1
	[[ -d "${RES}/multiqc_data" ]] || die "multiqc wrote no data directory"
	log "qc_report generated"
}

#=============================================================================
# 9 · publish — say what produced this output
#=============================================================================

stage_publish() {
	local samples_json metrics_json reads outputs_json st ty pa sum entry n sep id cond rep lt r1 r2 git_sha finished_at run_id
    {   
	printf 'run_started\t%s\n'  "$STARTED_AT"
        printf 'run_finished\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'samplesheet\t%s\n'  "$SHEET"
        printf 'reference\t%s\n'    "$FASTA"
        printf 'git_commit\t%s\n'   "$(git describe --always --dirty 2>/dev/null || echo unknown)"
        printf 'bwa\t%s\n'          "$(bwa 2>&1 | grep -i version | head -1)"
        printf 'samtools\t%s\n'     "$(samtools --version | head -1)"
        printf 'fastp\t%s\n'        "$(fastp --version 2>&1 | head -1)"
        printf 'gatk\t%s\n'         "$(gatk --version 2>&1 | head -1)"
    } > "${DB}/run_info.tsv"
    
	# populate samples file
	samples_json=""
	sep=""
	while IFS=, read -r id cond rep lt r1 r2; do
    		samples_json="${samples_json}${sep}{\"sample_id\":\"${id}\",\"library_type\":\"${lt}\",\"condition\":\"${cond}\"}"
    		sep=","
        done < <(tail -n +2 "$SHEET")
	# populate metrics file
    metrics_json=""
	sep=""
    while IFS=, read -r id cond rep lt r1 r2; do
			n=$(gzip -dc "${TRIM}/${id}_R1.trim.fastq.gz" | wc -l)
        	reads=$(( n / 4 ))
            metrics_json="${metrics_json}${sep}{\"sample_id\":\"${id}\",\"metric\":\"reads_after_trim\",\"value\":${reads},\"unit\":\"count\",\"stage\":\"trim\"}"
			sep=","
    done < <(tail -n +2 "$SHEET")
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
		sum=$(shasum -a 256 "${RES}/${pa}" | awk '{print $1}')
		outputs_json="${outputs_json}${sep}{\"stage\":\"${st}\",\"type\":\"${ty}\",\"path\":\"${pa}\",\"checksum\":\"sha256:${sum}\"}"
		sep=","
	done
	
	# publish heredoc
	git_sha=$(git describe --always --dirty 2>/dev/null || echo unknown)
	finished_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	run_id="${finished_at}-$$"

	cat > "${RES}/manifest.json" << EOF
	{
		"pipeline": {
			"name": "variant-call",
			"version": "1.0.0",
			"implementation": "bash",
			"git_sha": "${git_sha}",
			"run_id": "${run_id}",
			"started_at": "${STARTED_AT}",
			"finished_at": "${finished_at}",
			"exit_status": "success"
			},
			"platform": { "kind": "laptop" },
			"reference": { "genome": "GRCh38.chr20" },
			"samples": [ ${samples_json} ],
			"outputs": [ ${outputs_json} ],
			"metrics": [ ${metrics_json} ] 
		}
EOF
}	

#=============================================================================
# the driver — ten stages, in order, one after another
#=============================================================================
# Run the stages in order and stop after the one named on the command line.
# `"stage_${stage}"` calls the function whose name is built from the stage name.
n=0
for stage in "${STAGES[@]}"; do
    log "===== stage ${n} : ${stage} ====="
    "stage_${stage}"
    [[ "$stage" == "$LAST" ]] && break
    n=$(( n + 1 ))
done
log " pipeline done"



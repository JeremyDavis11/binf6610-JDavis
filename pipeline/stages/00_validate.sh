# shellcheck shell=bash

stage_validate() {
	local id cond rep lt r1 r2 n1 n2 problems=0 before=0
	
	while IFS=, read -r id cond rep lt r1 r2; do

		# check if a row had a valid sample ID
		[[ -n "$id" ]] || { log "a row has no sample_id"; problems=$(( problems + 1 )); continue; }

		# check if already validated
		if [[ -s "${LOG}/${id}.validated" ]]; then log "$id: inputs already verified"; continue; fi
    	before=$problems
	
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

		# timestamp issues
		if (( problems == before )); then
    	date -u +%Y-%m-%dT%H:%M:%SZ > "${LOG}/${id}.validated"
		fi

    	done < <(rows "$SHEET" "$SAMPLE")

    # duplicate sample ids. sort | uniq -d prints only the repeats.
    local dupes
    dupes=$(rows "$SHEET" | cut -d, -f1 | sort | uniq -d)
    [[ -z "$dupes" ]] || { log "duplicate sample_id: $dupes"; problems=$(( problems + 1 )); }
    
    # the reference is where the config says it is
    [[ -s "$FASTA" ]] || { log "no FASTA at ${FASTA}"; problems=$(( problems + 1 )); }
    [[ -s "${INDEX}.bwt" ]]           || { log "no BWA index at ${INDEX}";     problems=$(( problems + 1 )); }
    [[ -s "${FASTA}.fai" ]]     || { log "no .fai at ${FASTA}.fai"; problems=$(( problems + 1 )); }
    [[ -s "${FASTA%.fa}.dict" ]] || { log "no .dict at ${FASTA%.fa}.dict"; problems=$(( problems + 1 )); }

    (( problems == 0 )) || die "validation failed with ${problems} problem(s)"
    log "validation passed"

}



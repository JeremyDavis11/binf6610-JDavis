Cohort file has a 16-line comment preamble. tail -n +2 only skips one line. Stripped by pattern instead: grep -v '^#'.

No FASTQ path column in the cohort file. Constructed in awk from sample_id: "dev/" $1 "_R1.fastq.gz".

native_layout and library_type disagree on NA12892 and NA12003 (PAIRED vs single). Treated library_type as authoritative. R1 only, empty r2_fastq, single-end invocations downstream.

awk quoting. Fields are unquoted ($1, not "$1"); concatenation is adjacency; statements need ; between them, including before else.

Unclosed quote / unfinished while block. Bash won't run any of a file with an unterminated quote or block, not just the offending lines. Symptom is silence or unexpected end of file. Stubbed unwritten stages with a log line so the file always parses.

Non-zero exit codes on a successful fetch. pipestatus showed 23 141 0 0 — head closing the pipe SIGPIPEs gzip (141) and write-errors curl (23). Under set -euo pipefail that killed the script on sample one. Added || true to the fetch pipeline. Consequence: exit status can't distinguish a good fetch from a 404, so curl -fs plus the gzip -t and line-count checks in stage_validate do the verification instead.

PIPESTATUS printed nothing. macOS shell is zsh, which spells it pipestatus. It also holds only the most recent pipeline.

Couldn't derive the ENA URL from the accession. The middle directory (.../ERR166/081/...) follows no rule that fit three examples (081, 001, 004). Query the API per accession instead: filereport?accession=${run}&result=read_run&fields=fastq_ftp, then tail -n +2 | cut -f2 | tr ';' '\n' | grep '_1\.fastq\.gz$'. Response is semicolon-separated and may include an unpaired .fastq.gz, hence the anchored grep.

R2 fetch nested inside the R1 if. Once R1 existed for every sample the outer test was false, so R2 never fetched. Made the two blocks siblings.

Reference not specified in the assignment. Reads cover chr20:1–10,000,000, so used UCSC chr20 (chr prefix, matching the instructions' region string). GATK is strict about contig names matching across files.

.dict swaps the extension rather than appending — chr20.dict, not chr20.fa.dict. Check uses ${FASTA%.fa}.dict. BWA's five index files share the FASTA name as prefix, so INDEX=${FASTA} and ${INDEX}.bwt is a fine proxy.

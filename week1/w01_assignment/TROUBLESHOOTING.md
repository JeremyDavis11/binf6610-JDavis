Written with AI assistance (Claude, Anthropic) for bash and awk syntax, debugging, and porting the demo pipeline's stage structure. Specific contributions: the ENA filereport API approach for URL resolution, || true for the SIGPIPE-under-pipefail problem, the @RG tag structure, the flagstat awk parse, the -V argument accumulation in stage 6, and the JSON string-building pattern in stage 9. Tool defaults and hard-filter thresholds from GATK and samtools documentation. Driver stage borrowed from example pipeline.

Cohort file has a 16-line comment preamble. tail -n +2 only skips one line. Stripped by pattern instead: grep -v '^#'.

No FASTQ path column in the cohort file. Constructed in awk from sample_id: "dev/" $1 "_R1.fastq.gz".

native_layout and library_type disagree on NA12892 and NA12003 (PAIRED vs single). Treated library_type as authoritative. R1 only, empty r2_fastq, single-end invocations downstream.

awk quoting. Fields are unquoted ($1, not "$1"); concatenation is adjacency; statements need ; between them, including before else.

Unclosed quote / unfinished while block. Bash won't run any of a file with an unterminated quote or block, not just the offending lines. Symptom is silence or unexpected end of file. Stubbed unwritten stages with a log line so the file always parses.

PIPESTATUS printed nothing. macOS shell is zsh, which spells it pipestatus. It also holds only the most recent pipeline.

Reference not specified in the assignment. Reads cover chr20:1–10,000,000, so used UCSC chr20 (chr prefix, matching the instructions' region string). GATK is strict about contig names matching across files.

.dict swaps the extension rather than appending — chr20.dict, not chr20.fa.dict. Check uses ${FASTA%.fa}.dict. BWA's five index files share the FASTA name as prefix, so INDEX=${FASTA} and ${INDEX}.bwt is a fine proxy.

Samplesheet contract has 6 comma seperated fields, not 5 tab seperated fields as originally designed. Shifted every field left by one, added `cond` and `rep` in place of the `run` field so extra information did not pile into the last field. 

stream confusion over three debugging cycles: FastQC prints `application/gzip` and GATK prints `Tool returned: 0` to stdout so a 2> redirect left both on the terminal. `> file 2>&1` captures both. The order matters since `2>&1` the `> file` leaves stderr on the terminal.

GenomicsDBImport from GATK refuses to write to an existing workspace, so every re-run fails until a `rm -rf "${OUT}/genomicsgb"`. Added a `rm -rf /genomicsdb` which is safe here.

`$vargs` is deliberately unquoted in the GenomicsDBImport call. Quoting it would pass all eight `-V` glags as a single argument rather than one at a time.

Defered stage 7 annotation per the discussion post from the TA. The stage table only lists VariantFiltration which does not annotate.

The VariantFiltration in stage 7 filters on `QD < 2.0` which is the standard GATK hard filter from the documentation. VariantFiltration makes a FILTER column in the GVCF rather than removing rows.

Stage 9's manifest did not have a an example in the demo pipeline. Built the stage from the manifest schema's `required` arrays and using `check_manifest.py`. `samples`, `metrics`, and `outputs` are accumulated in loops using an initially empty `sep` that becomes a `,` after the first pass so no trailing commas are appended. The closing `EOF` line of the stage 9 heredoc must be flush left to run properly.

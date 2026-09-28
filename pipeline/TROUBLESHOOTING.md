missing -L on the HaplotypeCaller slowed down analysis significantly because it was scanning the whole reference. defined the genomic region in `common.sh` as `$REGION=Chr20:1-10000000` then passed that to stage 5 

| breakage | result |
|---|---|
|`--time=00:02:00`| state TIMEOUT, ExitCode 0:15, elapsed time of 2:25 against a 2:00 limit. Log stops at stage 3 mid-alignment. On disk: complete output through stage 2, an unifinsed `.bam.tmp` file plus the `.validated` marker. |
|make one task `exit 1` with the cohort job on `afterok` | State CANCELLED, reason: dependency, elapsed time on 02_cohort.sbactch: 00:00:00. 7/8 samples completed successfully, and without the dependency the pipeline wold hace proceeded to a 7 sample cohort VCF silently. |
|`--array=1-9` against the 8 row samplesheet| state: FAILED, ExitCode 64:0, elapsed 7 seconds on nonexistant sample 9. Log names the missing row explicitly. Without the guard an empty `$SAMPLE` means an empty filter, which matches all rows. The task would have re-done the whole cohort and exited 0 silently. |
|`scancel` mid-wite, then resubmit | Resume worked correctly and recognized completed steps. `.validated` marker meant tat stage 0 skipped a full re-read of FASTQs. fastqc zip existed so stage 1 skipped. Trimmed FASTQs were completed so stage 2 skipped. `align/` was empty, so stage 3 ran. Each guard checked the existence of these files, not the integrety. A half-written trimmed FASTQ file would look complete to the check line and be trusted. |
 

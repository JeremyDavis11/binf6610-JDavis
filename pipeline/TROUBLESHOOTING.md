## Week 2 Troubleshooting
missing -L on the HaplotypeCaller slowed down analysis significantly because it was scanning the whole reference. defined the genomic region in `common.sh` as `$REGION=Chr20:1-10000000` then passed that to stage 5 

| breakage | result |
|---|---|
|`--time=00:02:00`| state TIMEOUT, ExitCode 0:15, elapsed time of 2:25 against a 2:00 limit. Log stops at stage 3 mid-alignment. On disk: complete output through stage 2, an unifinsed `.bam.tmp` file plus the `.validated` marker. |
|make one task `exit 1` with the cohort job on `afterok` | State CANCELLED, reason: dependency, elapsed time on 02_cohort.sbactch: 00:00:00. 7/8 samples completed successfully, and without the dependency the pipeline wold hace proceeded to a 7 sample cohort VCF silently. |
|`--array=1-9` against the 8 row samplesheet| state: FAILED, ExitCode 64:0, elapsed 7 seconds on nonexistant sample 9. Log names the missing row explicitly. Without the guard an empty `$SAMPLE` means an empty filter, which matches all rows. The task would have re-done the whole cohort and exited 0 silently. |
|`scancel` mid-wite, then resubmit | Resume worked correctly and recognized completed steps. `.validated` marker meant tat stage 0 skipped a full re-read of FASTQs. fastqc zip existed so stage 1 skipped. Trimmed FASTQs were completed so stage 2 skipped. `align/` was empty, so stage 3 ran. Each guard checked the existence of these files, not the integrety. A half-written trimmed FASTQ file would look complete to the check line and be trusted. |
 
---

# Week 3 troubleshooting

## Breakage 1
In a scratch directory, build `FROM ubuntu (no tag) with RUN apt-get update && apt-get install -y curl`; a day later rebuild with `docker build --pull --no-cache`
The full list of packages in the day 1 build of the container are in `packages-day1.txt` and the packages for the day 2 build are found in `packages-day2.txt`
Lines that differ between packages (day 1 then day 2):
```
< ii  openssl                        3.5.5-1ubuntu3.5                   arm64        Secure Sockets Layer toolkit - cryptographic utility
---
> ii  openssl                        3.5.5-1ubuntu3.6                   arm64        Secure Sockets Layer toolkit - cryptographic utility
```
`openssl` went from `3.5.5-1ubuntu3.5` to `3.5.5-1ubuntu3.6`. `apt-get update && apt-get install -y curl` found live Ubuntu repositories, and between the two builds (~72 hours), Ubuntu published a new version of `openssl`. 
Identical Dockerfile produced two different images. This is why you should pin every version of packages in a container to be properly reproducable. 

## Breakage 2
Remove `--bind` from one job script and run one sample
Results:
Pipeline stopped at `setup_dirs` before any stage ran. No stage banner was printed in the logs.
Printed seven `mkdir: cannot create directory '/scratch': Read-only file system` messages. `mkdir -p` is called with seven directory arguments and each fails.
Exit Code: 1 FAILED
The container could not see: the `/scratch/$USER` directory.


## Breakage 3
Remove the --env THREADS=… line from one job script and run one sample
Results:
`[main] CMD: bwa mem -t 4 -R @RG\tID:NA12878\tSM:NA12878\tLB:NA12878\tPL:ILLUMINA\tPU:NA12878`
I asked for 8 cores in my `--env THREADS`. without that line, the pipeline defaulted to 4 threads as defined as the default in `lib/common.sh`.

# Breakage 4
On Explorer, `apptainer pull --arch arm64 arm.sif docker://ubuntu:24.04`, then run anything out of it
Result:
Pull was successful.
when running a job with this image: 
FATAL:   While checking container encryption: could not open image /scratch/davis.jer/arm.sif: the image's architecture (arm64) could not run on the host's (amd64)
arm64 images run on Apple Silicon natively, but not on Explorer.

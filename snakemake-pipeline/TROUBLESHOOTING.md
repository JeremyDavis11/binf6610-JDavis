# Assignment 5 - Snakemake pipeline breakages

# Break 1

## Break
On your laptop, stop a smoke run halfway with Ctrl-C, then run the same command

## Result
When I stopped the run part way in I got the message
```
WorkflowError:
At least one job did not complete successfully.
```

When I re-ran the same command I got the message
```
IncompleteFilesException:
The files below seem to be incomplete. If you are sure that certain files are not incomplete, mark them as complete with

    snakemake --cleanup-metadata <filenames>

To re-generate the files rerun your command with the --rerun-incomplete flag.
Incomplete files:
work/fastqc/smoke_03
```

I then re-ran the same command with the `--rerun-incomplete` flag, which has the pipeline re-generates the incomplete file.

After re-running 15/16 jobs ran, all but the first completed one.

# Break 2

## Break
Change the `log:` of your stage-3 rule to `"logs/bwa_mem.log"`, without `{sample}`, and run `snakemake -n`

## Result

Error contents:
RuleException in file "/Users/jeremydavis/school/computation6610/snakemake-pipeline/Snakefile", line 135:
Not all output, log and benchmark files of rule bwa_mem contain the same wildcards. This is crucial though, in order to avoid that two or more jobs write to the same file.

Snakemake refused it because the output and logs for a rule must use the same wildcards in Snakemake so two or more of the bwa_mem runs on different samples don't end up in the same log.

# Break 3

## Break
Delete both `wildcard_constraints`: from your stage-2 rules, and run `snakemake -n`

## Result

Exception:
AmbiguousRuleException:
Rules fastp_single and fastp_paired are ambiguous for the file work/trim/smoke_03_R1.trim.fastq.gz.
Consider starting rule output with a unique prefix, constrain your wildcards, or use the ruleorder directive.
Wildcards:
	fastp_single: sample=smoke_03
	fastp_paired: sample=smoke_03
Expected input files:
	fastp_single: ../smoke/smoke_03_R1.fastq.gz work/validate/samplesheet.csv
	fastp_paired: ../smoke/smoke_03_R1.fastq.gz work/validate/samplesheet.csv
Expected output files:
	fastp_single: work/trim/smoke_03_R1.trim.fastq.gz work/trim/smoke_03.fastp.json work/trim/smoke_03.fastp.html
	fastp_paired: work/trim/smoke_03_R1.trim.fastq.gz work/trim/smoke_03_R2.trim.fastq.gz work/trim/smoke_03.fastp.json work/trim/smoke_03.fastp.html

`fastp_single` and `fastp_paired` caused the AmbiguousRuleException and names the smoke_03 single ended file.

# Break 4

## Break
On your first Explorer run, `delete software-deployment-method: apptainer` from `profiles/explorer/profile.yaml`

## Result
The `fast_p` rule failed, presumably because `validate` didn't need anything from the containers and `fast_p` did.
`fast_p` jobs exited with exit code 1
Log file contents of first failed job: 
/usr/bin/bash: line 1: fastp: command not found

AI Disclosure: Anthropic's Claude assisted in debugging three total rules and in diagnosing why the pipeline ran to completion in break 3.

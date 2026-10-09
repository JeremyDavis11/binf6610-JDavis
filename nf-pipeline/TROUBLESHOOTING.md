| break | effect |
|---|---|
| smoke run stages cached before `-resume`: VALIDATE, QC_RAW, TRIM, ALIGN, and 1/3 POSTPROCESS | stages run after `resume`: 2/3 POSTPROCESS, QUANTIFY, MERGE, ANALYZE, QC_REPORT, PUBLISH |
| stage 3 align call in `main.nf`: ALIGN(TRIM.out.reads, bwa_index, fasta.name) to ALIGN(TRIM.out.reads, bwa_index, channel.of(fasta.name)) | `BWA_MEM` ran one sample, silently completed |
| modules/trim.nf: n=\$(gzip -dc ${meta.id}_R1.trim.fastq.gz | wc -l) to n=$(gzip -dc ${meta.id}_R1.trim.fastq.gz | wc -l) | `.command.sh`, `.command.err`, and `bash .command.run` results listed below. `bash .command.run` ran until the smoke_02, the paired sample, then hit a syntax error and exited. This is because the `$` without a `\` was on that branch of the command |
| set timelimit to 2m for process QUANTIFY in `nextflow.config` | exit status = 140, State=FAILED, elapsed=00:01:41, Timelimit=00:02:00. The pipeline never hit a TIMEOUT because when it requested resources, nextflow inserted a line: `#SBATCH --signal B:USR2@30` which creates a warning signal 30 seconds prior to the time limit. 

## Breakage 3 file outputs

### .command.sh`
```
#!/bin/bash -euo pipefail
fastp -w 1 -i smoke_02_R1.fastq.gz -I smoke_02_R2.fastq.gz -o smoke_02_R1.trim.fastq.gz \
          -O smoke_02_R2.trim.fastq.gz -j smoke_02.fastp.json -h smoke_02.fastp.html
n=smoke_02gzip -dc smoke_02_R1.trim.fastq.gz | wc -l)
(( n > 0 )) || { echo ": nothing survived trimming" >&2; exit 1; }
```

### .command.err
``` 
Read1 before filtering:
total reads: 100000
total bases: 15000000
Q20 bases: 15000000(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read2 before filtering:
total reads: 100000
total bases: 15000000
Q20 bases: 15000000(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read1 after filtering:
total reads: 100000
total bases: 14974318
Q20 bases: 14974318(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read2 after filtering:
total reads: 100000
total bases: 14974318
Q20 bases: 14974318(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Filtering result:
reads passed filter: 200000
reads failed due to low quality: 0
reads failed due to too many N: 0
reads failed due to too short: 0
reads failed due to adapter dimer: 0
reads with adapter trimmed: 658
bases trimmed due to adapters: 51364

Duplication rate: 0.003%

Insert size peak (evaluated by paired-end reads): 268

JSON report: smoke_02.fastp.json
HTML report: smoke_02.fastp.html

fastp -w 1 -i smoke_02_R1.fastq.gz -I smoke_02_R2.fastq.gz -o smoke_02_R1.trim.fastq.gz -O smoke_02_R2.trim.fastq.gz -j smoke_02.fastp.json -h smoke_02.fastp.html 
fastp v1.3.7, time used: 2 seconds
/Users/jeremydavis/school/computation6610/nf-pipeline/work/00/dbee4fd84d31a186529e0fe9606dd1/.command.sh: line 4: syntax error near unexpected token `)'
```

### bash .command.run
```
Read1 before filtering:
total reads: 100000
total bases: 15000000
Q20 bases: 15000000(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read2 before filtering:
total reads: 100000
total bases: 15000000
Q20 bases: 15000000(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read1 after filtering:
total reads: 100000
total bases: 14974318
Q20 bases: 14974318(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Read2 after filtering:
total reads: 100000
total bases: 14974318
Q20 bases: 14974318(100%)
Q30 bases: 0(0%)
Q40 bases: 0(0%)

Filtering result:
reads passed filter: 200000
reads failed due to low quality: 0
reads failed due to too many N: 0
reads failed due to too short: 0
reads failed due to adapter dimer: 0
reads with adapter trimmed: 658
bases trimmed due to adapters: 51364

Duplication rate: 0.003%

Insert size peak (evaluated by paired-end reads): 268

JSON report: smoke_02.fastp.json
HTML report: smoke_02.fastp.html

fastp -w 1 -i smoke_02_R1.fastq.gz -I smoke_02_R2.fastq.gz -o smoke_02_R1.trim.fastq.gz -O smoke_02_R2.trim.fastq.gz -j smoke_02.fastp.json -h smoke_02.fastp.html 
fastp v1.3.7, time used: 1 seconds
/Users/jeremydavis/school/computation6610/nf-pipeline/work/00/dbee4fd84d31a186529e0fe9606dd1/.command.sh: line 4: syntax error near unexpected token `)'
exit: 2
```

AI Disclosure: Used Anthropic's Claude for some nextflow syntax and debugging, and to define `--signal B:USR2@30` then verified independently. 

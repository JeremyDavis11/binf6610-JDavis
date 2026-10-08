// Stage 1 - qc_raw - FastQC on reads
process QC_RAW {
    tag "${meta.id}"
    container params.containers.fastqc

    input:
    tuple val(meta), path(reads)

    output:
    path '*_fastqc.zip', emit: zip

    script:
    """
    fastqc -q -t ${task.cpus} ${reads} -o .
    """
}
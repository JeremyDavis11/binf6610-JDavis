// Stage 3 - Align
process ALIGN {
    tag "${meta.id}"
    container params.containers.bwa

    input:
    tuple val(meta), path(reads)
    path index
    val index_name

    output:
    tuple val(meta), path("${meta.id}.bam"), emit: bam
    path "${meta.id}.bwamem.log", emit: log

    script:
    def rg = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tLB:${meta.id}\\tPL:ILLUMINA\\tPU:${meta.id}"
    """
    bwa mem -t ${task.cpus} -R "${rg}" ${index_name} ${reads} 2> ${meta.id}.bwamem.log \\
    | samtools view -b -o ${meta.id}.bam
    """
    }
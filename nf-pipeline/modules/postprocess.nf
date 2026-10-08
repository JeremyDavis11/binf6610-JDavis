// Stage 4 - postprocess
process POSTPROCESS {
    tag "${meta.id}"
    container params.containers.gatk4

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.markdup.bam"), path("${meta.id}.markdup.bam.bai"), emit: bam
    path "${meta.id}.flagstat.txt", emit: flagstat
    path "${meta.id}.markdup.metrics.txt", emit: markdup_metrics
    
    // left off -T flag from samtools sort. It spills beside the output by default and the work dir
    // for NF aldready lands in /scratch. If cluster run is slow, I will re-evaluate. 
    script:
    """
    samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam ${meta.id}.bam
    gatk MarkDuplicates -I ${meta.id}.sorted.bam -O ${meta.id}.markdup.bam -M ${meta.id}.markdup.metrics.txt > ${meta.id}.gatk.log 2>&1
    samtools index -@ ${task.cpus} ${meta.id}.markdup.bam
    samtools flagstat -@ ${task.cpus} ${meta.id}.markdup.bam > ${meta.id}.flagstat.txt
    """
}

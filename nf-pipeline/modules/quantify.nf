process QUANTIFY {
    tag "${meta.id}"
    container params.containers.gatk4

    input:
    tuple val(meta), path(bam), path(bai)
    path fasta
    path fai
    path dict

    output:
    tuple path("${meta.id}.g.vcf.gz"), path("${meta.id}.g.vcf.gz.tbi"), emit: gvcf

    script:
    """
    gatk HaplotypeCaller -R ${fasta} -I ${meta.id}.markdup.bam -O ${meta.id}.g.vcf.gz -ERC GVCF -L ${params.region} --tmp-dir . > ${meta.id}.hc.log 2>&1
    """
}
// 7 - Analyze and filter

process ANALYZE {
    tag "cohort"
    container params.containers.gatk4

    input:
    tuple path(vcf), path(tbi)
    path fasta
    path fai
    path dict

    output:
    tuple path("cohort.filtered.vcf.gz"), path("cohort.filtered.vcf.gz.tbi"), emit: filtered

    script:
    """
    gatk VariantFiltration -R ${fasta} \\
    -V ${vcf} -O cohort.filtered.vcf.gz \\
    --filter-name "QD2" --filter-expression "QD < 2.0"
    """
}
// 6 - Merge

process MERGE {
    tag "cohort"
    container params.containers.gatk4

    input:
    path gvcfs
    path fasta
    path fai
    path dict

    output:
    tuple path("cohort.vcf.gz"), path("cohort.vcf.gz.tbi"), emit: cohort

    script:
    def vargs = gvcfs.findAll { f -> f.name.endsWith('.g.vcf.gz') }
        .collect { f -> "-V ${f}" }
        .join(' ')
    """
    gatk GenomicsDBImport ${vargs} --genomicsdb-workspace-path genomicsdb -L \\
    ${params.region} --tmp-dir .
    gatk GenotypeGVCFs -R ${fasta} -V gendb://genomicsdb -O cohort.vcf.gz \\
    --tmp-dir . > genotypegvcfs.log 2>&1
    """


}
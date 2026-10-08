process VALIDATE {
    container params.containers.tools

    input:
    path samplesheet
    path fastqs

    output:
    path samplesheet, emit: sheet

    script:
    """
    validate_samplesheet.sh ${samplesheet}
    """

}
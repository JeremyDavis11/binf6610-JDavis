// 8 - MultiQC report

process QC_REPORT {
    tag "cohort"
    container params.containers.multiqc

    input:
    path qc_files

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data', emit: data

    script:
    """
    multiqc .
    """
}

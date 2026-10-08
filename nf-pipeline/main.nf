// includes
include { QC_RAW } from './modules/qc_raw'
include { TRIM } from './modules/trim'
include { ALIGN } from './modules/align'
include { POSTPROCESS } from './modules/postprocess'
include { QUANTIFY } from './modules/quantify'
include { MERGE } from './modules/merge'
include { ANALYZE } from './modules/analyze'
include { QC_REPORT } from './modules/qc_report'
include { PUBLISH } from './modules/publish'
include { VALIDATE } from './modules/validate'

// Workflow
workflow {
    // Inputs
    // One item per sample: [meta, reads], with meta = [id: ..., single_end: ...]
    main:
    sheet = file(params.samplesheet)
    ch_input = channel.fromPath(sheet)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, single_end: row.library_type == 'single']
            def r1 = sheet.parent.resolve(row.r1_fastq)
            def reads = meta.single_end ? [r1] : [r1, sheet.parent.resolve(row.r2_fastq)]
            [meta, reads]
        }
    
    ch_fastqs = ch_input
        .map { _meta, reads -> reads}
        .flatten()
        .collect()
    
    
    fasta = file(params.ref)
    fai = file("${params.ref}.fai")
    dict = file(params.ref.replaceAll(/\.fa$/, '.dict')) // swaps .fa for .dict 
    bwa_index = file("${params.ref}.{amb,ann,bwt,pac,sa}")


    VALIDATE(sheet, ch_fastqs)
    
    ch_samples = VALIDATE.out.sheet 
    .splitCsv(header: true)
    .map { row ->
        def meta = [id: row.sample_id, single_end: row.library_type == 'single']
        def r1 = sheet.parent.resolve(row.r1_fastq)
        def reads = meta.single_end ? [r1] : [r1, sheet.parent.resolve(row.r2_fastq)]
        [meta, reads]
    }

    // Stages
    QC_RAW(ch_samples)
    TRIM(ch_samples)
    ALIGN(TRIM.out.reads, bwa_index, fasta.name)
    POSTPROCESS(ALIGN.out.bam)
    QUANTIFY(POSTPROCESS.out.bam, fasta, fai, dict)
    MERGE(QUANTIFY.out.gvcf.collect(), fasta, fai, dict)
    ANALYZE(MERGE.out.cohort, fasta, fai, dict)

    ch_qc = QC_RAW.out.zip
        .mix(TRIM.out.json, POSTPROCESS.out.flagstat, POSTPROCESS.out.markdup_metrics)
        .collect()
    QC_REPORT(ch_qc)

    ch_results = MERGE.out.cohort
        .mix(ANALYZE.out.filtered, QC_REPORT.out.report)
        .collect()
    PUBLISH(sheet, ch_results)

    publish:
    cohort = MERGE.out.cohort
    filtered = ANALYZE.out.filtered
    multiqc = QC_REPORT.out.report
    multiqc_data = QC_REPORT.out.data
    manifest = PUBLISH.out.manifest
    samples = PUBLISH.out.samples
}

// output results
output {
    cohort {
        path '.'
    }
    filtered {
        path '.'
    }
    multiqc {
        path '.'
    }
    multiqc_data {
        path '.'
    }
    manifest {
        path '.'
    }
    samples {
        path '.'
    }
}
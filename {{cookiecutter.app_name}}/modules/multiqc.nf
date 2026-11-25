nextflow.enable.types = true

process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0'
    label 'small_job'

    input:
    fastqc_logs: Bag<Path>

    output:
    record(
        report: file('multiqc_report.html'),
        data: file('multiqc_data')
    )

    script:
    """
    multiqc .
    """
}
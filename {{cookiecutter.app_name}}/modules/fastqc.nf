nextflow.enable.types = true

process FASTQC {
    tag "${meta.sample}"
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    label 'medium_job'

    input:
    tuple(meta: Record, fastq_1: Path, fastq_2: Path?)

    output:
    logs: Tuple = tuple(meta, file("fastqc_${meta.sample}_logs"))

    script:
    fq2 = fastq_2 ? "${fastq_2}" : ''
    """
    mkdir fastqc_${meta.sample}_logs
    fastqc --outdir fastqc_${meta.sample}_logs --format fastq ${fastq_1} ${fq2} -t ${task.cpus}
    """
}

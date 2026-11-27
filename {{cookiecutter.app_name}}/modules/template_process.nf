// Enable typed syntax
// See: https://docs.seqera.io/nextflow/process-typed
nextflow.enable.types = true

// Define the process
process generate_report {
    // Define directives
    // See: https://docs.seqera.io/nextflow/process#processes
    tag "${meta.sample}"
    container ''
    label 'small_job'

    // Define input
    // See: https://docs.seqera.io/nextflow/process-typed#inputs
    input:
    tuple(meta: Record, infile: Path)

    // Define staging directives
    // See: https://docs.seqera.io/nextflow/process-typed#stage-directives
    stage:
    stageAs infile, 'stageDir/*'

    // Define output(s)
    // See: https://docs.seqera.io/nextflow/process-typed#outputs
    output:
    out: Tuple = tuple(meta, file("${meta.sample}.output"))

    // Define code to execute
    // See: https://docs.seqera.io/nextflow/process-typed#script
    script:
    """
    cp "${infile}" "${meta.sample}.output"
    """
}

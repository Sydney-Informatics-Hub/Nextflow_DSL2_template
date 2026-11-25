#!/usr/bin/env nextflow
nextflow.enable.types = true

// =================================================================
//
// main.nf is the main pipeline script for a nextflow pipeline
// This file should contain the following sections:
//     Include statements for importing processes from `modules/*.nf`
//     Channel definitions
//     Workflow structure
//     Workflow summary logs
//
// Examples are included for each section. Remove them and replace
// with project-specific code. For more information see:
// https://docs.seqera.io/nextflow
//
// ===================================================================

// Import processes or subworkflows to be run in the workflow
// Each of these is a separate .nf script saved in the modules/ and 
// subowrkflows/ directories, respectively
// See https://training.nextflow.io/latest/hello_nextflow/04_hello_modules/

include { paramsSummaryLog; paramsHelp; validateParameters } from 'plugin/nf-schema'
include { FASTQC } from './modules/fastqc'
include { MULTIQC } from './modules/multiqc'

// Define pipeline parameters, including their types
// See https://docs.seqera.io/nextflow/workflow#parameters
params {
    // A `?` after the type means the parameter is nullable, i.e. it can be left blank
    // Although `input` is required, we want to use nf-schema to manage parameters,
    // so we bypass Nextflow's checks
    input: Channel<SampleSheet>? = null  // Nextflow reads this in automatically as a SampleSheet type (defined below)
    help: Boolean                = false
    multiqc_title: String?       = null
}

// Define the samplesheet format
record SampleSheet {
    sample: String
    fastq_1: Path
    fastq_2: Path?
    min_len: Integer?
    min_qual: Integer?
    platform: String?
    seq_centre: String?
}

// def printInfo() {
//     // Print pipeline info to the terminal and log
//     log.info """\

//     =======================================================================================
//     Name of the pipeline - nf
//     =======================================================================================

//     Created by <YOUR NAME>
//     Find documentation @ https://sydney-informatics-hub.github.io/template-nf-guide/
//     Cite this pipeline @ INSERT DOI

//     =======================================================================================
//     Workflow run parameters
//     =======================================================================================
//     input       : ${params.input}
//     results     : ${params.outdir}
//     workDir     : ${workflow.workDir}
//     =======================================================================================

//     """.stripIndent()
// }

// def helpMessage() {
//     /// Help function
//     // This is an example of how to set out the help function that
//     // will be run if run command is incorrect or missing.
//     log.info"""
//     Usage:  nextflow run main.nf --input <samples.tsv>

//     Required Arguments:

//     --input     Specify full path and name of sample input file.

//     Optional Arguments:

//     --outdir    Specify path to output directory.

//     """.stripIndent()
// }

// Define workflow structure.
// See https://docs.seqera.io/nextflow/workflow
workflow {

    main:
    // Start by printing run information, including non-default parameters,
    // working directory, run name, etc.
    // This function is provided by the nf-schema plugin
    log.info paramsSummaryLog()

    // Show help message and exit immediately if --help is provided
    if ( params.help ){
        // Invoke the nf-schema help function and exit
        log.info paramsHelp()
        exit(1, null)
    }

    // Validate parameters
    // The nf-schema plugin checks the parameters against the
    // `nextflow_schema.json` file. Use that file to specify whether
    // parameters are required or if files need to exist.
    // See https://nextflow-io.github.io/nf-schema/latest/
    validateParameters(parameters_schema: "${projectDir}/nextflow_schema.json")

    // If none of the above are a problem, then run the workflow

    // DEFINE CHANNELS
    // See https://docs.seqera.io/nextflow/workflow#channels-and-values
    // See https://training.nextflow.io/latest/hello_nextflow/02_hello_channels/

    // Re-structure the samplesheet
    // Some data from the samplesheet is metadata that is better passed as a single map object
    samplesheet = params.input
        .map { row -> tuple(
            row.subMap( ['sample', 'min_len', 'min_qual', 'platform', 'seq_centre'] ),
            row.fastq_1,
            row.fastq_2
        ) }

    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - RUN FASTQC
    fqc_logs = FASTQC(samplesheet)

    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - RUN MULTIQC
    // Define input channel for MULTIQC
    multiqc_in = fqc_logs
        .map { _meta, logs -> logs }
        .collect()

    multiqc_out = MULTIQC(multiqc_in)

    publish:
    fastqc_logs = fqc_logs
    multiqc_outputs = multiqc_out

    onComplete:
    // Print a workflow execution summary
    def summary = """
    =======================================================================================
    Workflow execution summary
    =======================================================================================

    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    outputDir   : ${workflow.outputDir}
    Exit status : ${workflow.exitStatus}

    =======================================================================================
    """
    log.info summary.replaceAll(/(^|\n)\s+/, '\n')

}

output {
    fastqc_logs {
        path 'fastqc'
    }
    multiqc_outputs {
        path 'multiqc'
    }
}

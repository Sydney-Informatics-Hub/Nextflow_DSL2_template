#!/usr/bin/env nextflow

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

include { validateParameters; samplesheetToList } from 'plugin/nf-schema'
include { FASTQC } from './modules/fastqc'
include { MULTIQC } from './modules/multiqc'

def printInfo() {
    // Print pipeline info to the terminal and log
    log.info """\

    =======================================================================================
    Name of the pipeline - nf
    =======================================================================================

    Created by <YOUR NAME>
    Find documentation @ https://sydney-informatics-hub.github.io/template-nf-guide/
    Cite this pipeline @ INSERT DOI

    =======================================================================================
    Workflow run parameters
    =======================================================================================
    input       : ${params.input}
    results     : ${params.outdir}
    workDir     : ${workflow.workDir}
    =======================================================================================

    """.stripIndent()
}

def helpMessage() {
    /// Help function
    // This is an example of how to set out the help function that
    // will be run if run command is incorrect or missing.
    log.info"""
    Usage:  nextflow run main.nf --input <samples.tsv>

    Required Arguments:

    --input     Specify full path and name of sample input file.

    Optional Arguments:

    --outdir    Specify path to output directory.

    """.stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://docs.seqera.io/nextflow/workflow
workflow {

    // Run the printInfo function to display pipeline info
    printInfo()

    // Validate parameters
    validateParameters(parameters_schema: "${projectDir}/nextflow_schema.json")

    // Show help message if --help is run or (||) a required parameter (input) is not provided
    if ( params.help || !params.input ){
        // Invoke the help function above and exit
        helpMessage()
        exit 1

        // consider adding some extra contigencies here.
        // could validate path of all input files in list?
        // could validate indexes for reference exist?
    }

    // If none of the above are a problem, then run the workflow

    // DEFINE CHANNELS
    // See https://docs.seqera.io/nextflow/workflow#channels-and-values
    // See https://training.nextflow.io/latest/hello_nextflow/02_hello_channels/

    // Read in the samplesheet
    samplesheet = channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))

    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - RUN FASTQC
    // Define input channel for FASTQC
    fastqc_in = samplesheet
        .map { meta, fq1, fq2 -> [ meta.sample, fq1, fq2 ] }  // We just want the FASTQs for FASTQC

    FASTQC(fastqc_in)

    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - RUN MULTIQC
    // Define input channel for MULTIQC
    multiqc_in = FASTQC.out.logs
        .map { _sample, logs -> logs }
        .collect()

    MULTIQC(multiqc_in)

    // Print a workflow execution summary
    workflow.onComplete = {
        def summary = """
        =======================================================================================
        Workflow execution summary
        =======================================================================================

        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        Exit status : ${workflow.exitStatus}
        results     : ${params.outdir}

        =======================================================================================
        """
        println summary.replaceAll(/(^|\n)\s+/, '\n')
    }
}

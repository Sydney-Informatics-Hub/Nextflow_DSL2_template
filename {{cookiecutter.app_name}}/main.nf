#!/usr/bin/env nextflow

// =================================================================
//
// main.nf is the main pipeline script for a nextflow pipeline
// This file should contain the following sections:
    // Include statements for importing processes from `modules/*.nf`
    // Channel definitions
    // Workflow structure
    // Workflow summary logs 

// Examples are included for each section. Remove them and replace
// with project-specific code. For more information see:
// https://docs.seqera.io/nextflow
//
// ===================================================================

// Import processes or subworkflows to be run in the workflow
// Each of these is a separate .nf script saved in the modules/ directory
// See https://training.nextflow.io/latest/hello_nextflow/04_hello_modules/

include { group_samples } from './modules/group_samples'
include { generate_report } from './modules/generate_report' 

def printInfo() {
    // Print a header for your pipeline
    log.info """\

    =======================================================================================
    Name of the pipeline - nf 
    =======================================================================================

    Created by <YOUR NAME> 
    Find documentation @ https://sydney-informatics-hub.github.io/Nextflow_DSL2_template_guide/
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

    --input		Specify full path and name of sample input file.

    Optional Arguments:

    --outdir	Specify path to output directory. 
        
    """.stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://docs.seqera.io/nextflow/workflow
workflow {

    printInfo()

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
    // See https://www.nextflow.io/docs/latest/channel.html#channels
    // See https://training.nextflow.io/basic_training/channels/ 

    // Read in the samplesheet
    samplesheet = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv( header: true )

    // DEMO CODE: MODIFY FOR YOUR OWN WORKFLOWS - parse and validate samplesheet
    // TODO

    check_input(Channel.fromPath(params.input, checkIfExists: true))

    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - SPLIT SAMPLESHEET DEPENDING ON SEQUENCING PLATFORM
    // See https://training.nextflow.io/basic_training/processes/#inputs 
    // Define the input channel for this process
    group_samples_in = check_input.out.checked_samplesheet

    // Run the process with its input channel
    group_samples(group_samples_in)
    
    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - EXAMPLE PROCESS - SUMMARISE COHORT FROM SAMPLESHEETS
    // Define the input channel for this process using Nextflow mix operator and some groovy (the use of 'map')
    // See: https://www.nextflow.io/docs/latest/operator.html
    generate_report_in = group_samples.out.illumina
                     .map { file -> tuple(file, 'Illumina') }
                     .mix(group_samples.out.pacbio
                          .map { file -> tuple(file, 'PacBio') })
    
    // DEMO CODE: DELETE FOR YOUR OWN WORKFLOWS - Run the process with its input channel
    generate_report(generate_report_in)

    // Print a workflow execution summary 
    workflow.onComplete {
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

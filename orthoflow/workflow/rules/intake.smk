import os
from orthoflow.workflow.rules.intake_utils import create_input_dictionary

ignore_non_valid_files = config.get('ignore_non_valid_files', IGNORE_NON_VALID_FILES_DEFAULT)
input_dictionary = create_input_dictionary(config["input_sources"], ignore_non_valid_files, warnings_dir=WARNINGS_DIR)

def check_configurations():
    configuration_warnings = []

    min_seqs = config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)
    if min_seqs < 3:
        configuration_warnings.append(f"The variable ortholog_min_seqs is {min_seqs} and should be 3 or larger. It has been automatically set to 3.")

    if not config["supermatrix"] and not config["supertree"]:
        configuration_warnings.append("Both the 'supermatrix' and 'supertree' variable are False in the configuration file. No tree will be made.")

    if not config["infer_tree_with_protein_seqs"] and not config["infer_tree_with_cds_seqs"]:
        configuration_warnings.append("Both the 'infer_tree_with_protein_seqs' and 'infer_tree_with_cds_seqs' variable are False in the configuration file.\nDefault method protein sequence is used.")

    # check whether configurations are present and not faulty
    config_dict = {"orthofinder_use_scogs" : bool, "orthofinder_use_snap_ogs" : bool, "ortholog_min_seqs" : int, "ortholog_min_taxa" : int, "minimum_trimmed_alignment_length_cds" : int, "minimum_trimmed_alignment_length_proteins" : int, "max_trimmed_proportion" : float, "use_orthofisher" : bool, "supermatrix" : bool, "supertree" : bool, "ignore_non_valid_files" : bool, "infer_tree_with_protein_seqs" : bool, "infer_tree_with_cds_seqs" : bool}
    for key in config_dict.keys():
        if not isinstance(config.get(key),config_dict[key]) and config.get(key) not in [0,1]:
            configuration_warnings.append(f"'{key}' configuration is missing from configuration file or faulty, so default has been assumed.")

    # check hmm files in configuration file
    if config["use_orthofisher"] == True:
        for file in config["orthofisher_hmmer_files"]:
            if not os.path.isfile(file):
                configuration_warnings.append(f"hmm file {file} does not exist and is not used as an hmm profile.")

    if len(configuration_warnings) > 0:
        configuration_warnings.insert(0, "Configuration file has raised warnings due to uncommon configurations.\n")
    config_warning_file = WARNINGS_DIR/"configuration_warnings.txt"
    config_warning_file.write_text("\n".join(str(item) for item in configuration_warnings))

rule input_sources_csv:
    """
    Writes the input dictionary as a CSV file.
    """
    output:
        "results/intake/input_sources.csv",
    run:
        check_configurations()
        input_dictionary.write_csv(output[0])


rule extract_cds:
    """
    Extracts CDS features from GenBank or fasta files.

    It also adds the taxon name to the sequence ID.
    """
    input:
        file=lambda wildcards: input_dictionary[wildcards.stub].file.resolve(),
    output:
        "results/intake/cds/{stub}.cds.fa",
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    params:
        data_type=lambda wildcards: input_dictionary[wildcards.stub].data_type,
        taxon_string=lambda wildcards: input_dictionary[wildcards.stub].taxon_string,
    log:
        LOG_DIR / "intake/extract_cds/{stub}.log"
    shell:
        """
        python {SCRIPT_DIR}/extract_cds.py --debug {input.file} {output} --data-type {params.data_type} --taxon-string  {params.taxon_string} --warnings-dir {WARNINGS_DIR} &> {log}
        """


rule translate:
    """
    Translates coding sequences to amino acid sequences using BioKIT.

    It relies on the `translation_table` field in the input.
    It expects a number there which corresponds with the NCBI genetic codes:
    https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes

    BioKIT is found here: https://github.com/JLSteenwyk/BioKIT
    """
    output:
        "results/intake/translated/{stub}.protein.fa",
    input:
        rules.extract_cds.output
    bibs:
        "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_dictionary[wildcards.stub].translation_table
    log:
        LOG_DIR / "intake/translate/{stub}.log"
    shell:
        "biokit translate_sequence {input} --output {output} --translation_table {params.translation_table} &> {log}"

def translated_files(*args):
    return [f"results/intake/translated/{stub}.protein.fa" for stub in input_dictionary.keys()]

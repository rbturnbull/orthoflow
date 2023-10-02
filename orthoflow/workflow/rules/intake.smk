from orthoflow.workflow.rules.intake_utils import create_input_dictionary
from orthoflow.workflow.scripts.check_config import check_configurations

ignore_non_valid_files = config.get('ignore_non_valid_files', IGNORE_NON_VALID_FILES_DEFAULT)
input_dictionary = create_input_dictionary(config["input_sources"], ignore_non_valid_files, warnings_dir=WARNINGS_DIR)

rule input_sources_csv:
    """
    Writes the input dictionary as a CSV file.
    """
    output:
        "results/intake/input_sources.csv",
    run:
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
    # bibs:
    #     "../bibs/biopython.bib"
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

    It also copies the translated files to the protein intake foler.
    """
    output:
        "results/intake/translated/{stub}.protein.fa",
    input:
        rules.extract_cds.output
    # bibs:
    #     "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_dictionary[wildcards.stub].translation_table
    log:
        LOG_DIR / "intake/translate/{stub}.log"
    shell:
        """
        biokit translate_sequence {input} --output {output} --translation_table {params.translation_table} &> {log}
        if [ ! -d "results/intake/protein" ]; then mkdir results/intake/protein; fi
        cp {output} results/intake/protein
        """

rule get_protein_sequence:
    """
    Gets protein Sequence from input files and copies them to intake files.
    """
    input:
        file=lambda wildcards: input_dictionary[wildcards.stub].file.resolve(),
    output:
        "results/intake/protein/{stub}.protein.fa",
    shell:
        "cp {input} {output}"

def protein_files(*args):
    check_configurations(input_dictionary, WARNINGS_DIR, ORTHOLOG_MIN_SEQS_DEFAULT, config)

    list_of_protein_sequences = []

    for key, value in input_dictionary.items():
        if value.data_type == 'Protein':
            list_of_protein_sequences.append(f"results/intake/protein/{key}.protein.fa")
        else:
            list_of_protein_sequences.append(f"results/intake/translated/{key}.protein.fa")
            
    return list_of_protein_sequences

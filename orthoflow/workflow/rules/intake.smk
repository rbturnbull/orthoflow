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


rule rename_sequences:
    """
    Renames the sequence IDs in the input file so that the ID includes the taxon name, the filename and that each ID is unique.
    
    It also extracts CDS features from GenBank files if necessary.
    """
    input:
        file=lambda wildcards: input_dictionary[wildcards.stub].file.resolve(),
    output:
        "results/intake/renamed/{stub}.renamed.fa",
    # bibs:
    #     "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    params:
        data_type=lambda wildcards: input_dictionary[wildcards.stub].data_type,
        taxon_string=lambda wildcards: input_dictionary[wildcards.stub].taxon_string,
    log:
        LOG_DIR / "intake/renamed/{stub}.log"
    shell:
        """
        python {SCRIPT_DIR}/rename_sequences.py --debug {input.file} {output} --data-type {params.data_type} --taxon-string  {params.taxon_string} --warnings-dir {WARNINGS_DIR} &> {log}
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
    input:
        rules.rename_sequences.output
    output:
        "results/intake/translated/{stub}.translated.fa",
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
        """


def protein_files(*args):
    check_configurations(input_dictionary, WARNINGS_DIR, ORTHOLOG_MIN_SEQS_DEFAULT, config)

    list_of_protein_sequences = []

    for key, value in input_dictionary.items():
        if value.data_type == 'Protein':
            list_of_protein_sequences.append(f"results/intake/renamed/{key}.renamed.fa")
        else:
            list_of_protein_sequences.append(f"results/intake/translated/{key}.translated.fa")
            
    return list_of_protein_sequences

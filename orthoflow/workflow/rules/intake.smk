from orthoflow.workflow.rules.intake_utils import create_input_dictionary

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

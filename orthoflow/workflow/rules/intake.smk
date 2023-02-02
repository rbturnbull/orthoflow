from orthoflow.workflow.rules.intake_utils import create_input_dictionary

input_dictionary = create_input_dictionary(config["input_sources"])


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
    """
    input:
        file=lambda wildcards: input_dictionary[wildcards.stub].file.resolve(),
    output:
        "results/intake/{stub}.cds.fa",
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    params:
        data_type=lambda wildcards: input_dictionary[wildcards.stub].data_type
    log:
        LOG_DIR / "intake/extract_cds/{source}.log"
    shell:
        """
        python {SCRIPT_DIR}/extract_cds.py --debug {input.file} {output} {params.data_type} &> {log}
        """


rule add_taxon:
    """
    Prepends the taxon name to the description of each sequence in a CDS file.
    """
    input:
        rules.extract_cds.output,
    output:
        "results/intake/taxon-added/{stub}.cds.fasta",
    conda:
        ENV_DIR / "typer.yaml"
    params:
        taxon=lambda wildcards: input_dictionary[wildcards.stub].taxon_string
    log:
        LOG_DIR / "intake/add_taxon/{source}.log"
    shell:
        "python {SCRIPT_DIR}/add_taxon.py --unique-counter {params.taxon} {input} {output} &> {log}"


rule translate:
    """
    Translates coding sequences to amino acid sequences using BioKIT.

    It relies on the `translation_table` column in the input CSV.
    It expects a number there which corresponds with the NCBI genetic codes:
    https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes

    BioKIT is found here: https://github.com/JLSteenwyk/BioKIT
    """
    output:
        "results/intake/translated/{stub}.protein.fa",
    input:
        rules.add_taxon.output
    bibs:
        "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_dictionary[wildcards.stub].translation_table
    log:
        LOG_DIR / "intake/translate/{source}.log"
    shell:
        "biokit translate_sequence {input} --output {output} --translation_table {params.translation_table} &> {log}"


def translated_files(*args):
    return [f"results/intake/translated/{stub}.protein.fa" for stub in input_dictionary.keys()]

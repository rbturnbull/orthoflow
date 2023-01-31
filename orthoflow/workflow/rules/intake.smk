import pandas as pd
from pathlib import Path


def validate_input():
    input_csv = config["input_sources"]
    try:
        df = pd.read_csv(input_csv)
    except FileNotFoundError as e:
        print(f"Could not find your input_sources file '{input_csv}'. Please check your config file.\n")
        raise SystemExit(e)
    for file in df["file"]:
        if not Path(file).exists():
            print(f"File '{file} does not exist. Please check your input file '{input_csv}'.")
            raise FileNotFoundError
    return df


input_csv = validate_input()


def input_sources_row(source):
    """
    Reads a row in the input CSV based on the first part of the filename (before a '.').

    Returns:
        pd.Series: The row which corresponds to the file.
    """
    index = input_csv['file'].apply(lambda x: x.split(".")[0]) == source
    if sum(index) != 1:
        raise Exception(f"Cannot find unique row with filename '{source}' in '{config['input_sources']}'")
    return input_csv[index]


def input_sources_item(source, column):
    """
    Reads a cell in the input CSV for a file and a column.
    """
    row = input_sources_row(source)
    val = row[column].item()

    # sanitize the string (remove spaces and other non-alpha-numeric characters)
    if isinstance(val, str):
        val = "".join([c if (c.isalnum() or c in "._-") else "_" for c in val])

    return val


rule extract_cds:
    """
    Extracts CDS features from GenBank or fasta files.

    """
    output:
        "results/intake/{source}.cds.fa",
    input:
        input_sources=config["input_sources"],
        file=lambda wildcards: Path(input_sources_item(wildcards.source, 'file')).resolve(),
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    params:
        is_genbank=lambda wildcards: input_sources_item(wildcards.source, 'data_type').lower()
        in ["genbank", "gb", "gbk"],
    log:
        LOG_DIR / "intake/extract_cds/{source}.txt"
    shell:
        """
        if [ "{params.is_genbank}" = "True" ] ; then
            python {SCRIPT_DIR}/extract_cds.py --debug {input.file} {output} Genbank &> {log}
        else
            python {SCRIPT_DIR}/extract_cds.py --debug {input.file} {output} fasta &> {log}
        fi

        # Sanitize the IDs
        # {{ sed '/^>/s/;/_/g;s/ //g;s/\[/_/g;s/\]/_/g' {output} > {output}.tmp && mv {output}.tmp {output} ; }} &>> {log}
        """

rule add_taxon:
    """
    Prepends the taxon name to the description of each sequence in a CDS file.
    """
    output:
        "results/intake/taxon-added/{source}.cds.fasta",
    input:
        rules.extract_cds.output,
    conda:
        ENV_DIR / "typer.yaml"
    params:
        taxon=lambda wildcards: input_sources_item(wildcards.source, 'taxon_string'),
    log:
        LOG_DIR / "intake/add_taxon/{source}.txt"
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
        "results/intake/translated/{source}.protein.fa",
    input:
        rules.add_taxon.output
    bibs:
        "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_sources_item(wildcards.source, 'translation_table'),
    log:
        LOG_DIR / "intake/translate/{source}.txt"
    shell:
        "biokit translate_sequence {input} --output {output} --translation_table {params.translation_table} &> {log}"

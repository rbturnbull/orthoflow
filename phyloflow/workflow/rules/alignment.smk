
rule mafft:
    """
    Aligns the protein (amino acid) file with MAFFT
    """
    output:
        combined="results/alignment/sequences.fa",
        alignment="results/alignment/alignment.fa"
    input:
        Path("results/orthologs/").glob('*.fa')
    bibs:
        "../bibs/mafft7.bib"
    log:
        "logs/mafft/mafft.log"
    threads: 4
    resources:
        time="00:10:00",
        mem="8G",
        cpus=4,
    conda:
        "../envs/mafft.yaml"
    shell:
        """
        cat {input} > {output.combined}
        mafft --thread {threads} --auto {output.combined} > {output.alignment}
        """


rule concat_nuc:
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    output:
        "results/alignment/sequences.cds.fa"
    input:
        cds=Path("results/taxon-added/"),
        alignment="results/alignment/alignment.fa"
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    shell:
        "python {SCRIPT_DIR}/concat_nuc.py --cds-dir {input.cds} --alignment {input.alignment} --output-file {output}"


rule thread_dna:
    """
    Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#protein-to-nucleotide-alignment

    The --stop argument keeps in stop codons which are otherwise removed.
    """
    output:
        aligned_cds="results/alignment/alignment.cds.fa",
    input:
        alignment="results/alignment/alignment.fa",
        cds="results/alignment/sequences.cds.fa"
    bibs:
        "../bibs/phykit.bib"
    conda:
        "../envs/phykit.yaml"
    shell:
        """
        phykit thread_dna --protein {input.alignment} --nucleotide {input.cds} --stop > {output}
        """


rule taxon_only:
    """
    Trim sequence IDs to taxon.
    
    At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier 
    and produce clean output for the next stages. 
    """
    output:
        "results/alignment/alignment.no_taxon.cds.fa"
    input:
        rules.thread_dna.output
    conda:
        "../envs/typer.yaml"
    shell:
        "python {SCRIPT_DIR}/remove_taxon.py {input} {output}"

rule mafft:
    """
    Aligns the protein (amino acid) file with MAFFT
    """
    input:
        "results/orthologs/{og}.orthosnap.fa"
    output:
        "results/alignment/{og}.alignment.fa"
    bibs:
        "../bibs/mafft7.bib"
    log:
        "logs/mafft/mafft-{og}.log"
    threads: 4
    resources:
        time="00:10:00",
        mem="8G",
        cpus=4,
    conda:
        "../envs/mafft.yaml"
    shell:
        """
        mafft --thread {threads} --auto {input} > {output}
        """


rule concat_nuc:
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    output:
        "results/alignment/{og}.seqs.cds.fa"
    input:
        cds=Path("results/taxon-added/"),
        alignment=rules.mafft.output
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
        "results/alignment/{og}.alignment.cds.fa"
    input:
        alignment=rules.mafft.output,
        cds=rules.concat_nuc.output
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
        "results/alignment/{og}.alignment.no_taxon.cds.fa"
    input:
        rules.thread_dna.output
    conda:
        "../envs/typer.yaml"
    shell:
        "python {SCRIPT_DIR}/taxon_only.py {input} {output}"


def all_alignments(wildcards):
    filtered_dir = Path(checkpoints.filter_orthofinder.get().output[0])
    return expand(rules.taxon_only.output, og=glob_wildcards(filtered_dir / "{og}.fa").og)


rule list_alignments:
    """
    List path to alignment files into a single text file for use in PhyKIT.
    """
    output:
        "results/alignment/alignments.txt",
    input:
        all_alignments
    shell:
        """
        ls -1 {input} > {output}
        """

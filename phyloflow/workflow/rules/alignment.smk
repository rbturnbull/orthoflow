
rule mafft:
    """
    Aligns the protein (amino acid) file with MAFFT
    """
    output:
        "results/alignment/alignment.fa"
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
        cat {input} > results/alignment/sequences.fa
        mafft --thread {threads} --auto results/alignment/sequences.fa > {output}
        """


rule translatorx:
    """
    Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.
    """
    output:
        "results/alignment/alignment.translated.out"
    input:
        "results/alignment/alignment.fa"
    bibs:
        "../bibs/TranslatorX.nbib"
    conda:
        "../envs/perl.yaml"
    shell:
        "perl {SCRIPT_DIR}/TranslatorX.pl -i {input} -o {output} -p M -t F -w 1 -c 5"


rule trim_seqIDs_to_taxon:
    """Trim sequence IDs to taxon."""
    input:
        "output/{og}.aln.fa"
    output:
        "output/{og}.trID.aln.fa"
    conda:
        "../envs/perl.yaml"
    shell:
        "perl {SCRIPT_DIR}/seqID_taxon_only.pl {input} {output}"
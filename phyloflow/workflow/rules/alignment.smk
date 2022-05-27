
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
    # log:
    #     "logs/mafft/mafft.log"
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


rule matching_cds:
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    output:
        "results/alignment/{source}.cds.fasta",
    input:
        cds="input_sources.csv",
        og="results/fasta/{source}.cds.fasta",
    conda:
        ENV_DIR / "biopython.yaml"
    shell:
        "python {SCRIPT_DIR}/matching_cds.py --cds-files {input.cds} --og-files {input.og}"


rule thread_dna:
    """
    Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#protein-to-nucleotide-alignment
    """
    output:
        "results/alignment/alignment.translated.out"
    input:
        "results/alignment/alignment.fa"
    bibs:
        "../bibs/phykit.bib"
    conda:
        "../envs/phykit.yaml"
    shell:
        "phykit thread_dna -p {input} -n <file> [-s]"


# rule translatorx:
#     """
#     Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.
#     """
#     output:
#         "results/alignment/alignment.translated.out"
#     input:
#         "results/alignment/alignment.fa"
#     bibs:
#         "../bibs/TranslatorX.nbib"
#     conda:
#         "../envs/perl.yaml"
#     shell:
#         "perl {SCRIPT_DIR}/TranslatorX.pl -i {input} -o {output} -p M -t F -w 1 -c 5"


rule trim_seqIDs_to_taxon:
    """
    Trim sequence IDs to taxon.
    
    - At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier and produce clean output for the next stages. 
    I wrote "ext_scripts/seqID_taxon_only.pl" to do this and added a rule for this. 
    We probably want this running in a conda environment to be safe but I haven't done that. 
    """
    input:
        "output/{og}.aln.fa"
    output:
        "output/{og}.trID.aln.fa"
    conda:
        "../envs/perl.yaml"
    shell:
        "perl {SCRIPT_DIR}/seqID_taxon_only.pl {input} {output}"
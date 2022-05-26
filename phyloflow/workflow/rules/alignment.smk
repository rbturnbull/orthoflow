rule mafft_aa:
    """
    Aligns the protein (amino acid) file with MAFFT
    """
    output:
        "output/{og}.aln.fa"
    input:
        "data/{og}"
    bibs:
        "../bibs/mafft7.bib"
    log:
        "logs/mafft/{og}.log"
    conda:
        "../envs/mafft.yaml"
    shell:
        "{{ mafft {input} > {output} ; }} &> {log}"


rule translatorx:
    """
    Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.
    """
    output:
        "output/{og}.translated.out"
    input:
        "output/{og}.aln.fa"
    bibs:
        "../bibs/TranslatorX.bib"
    conda:
        "../envs/perl.yaml"
    shell:
        "perl {SCRIPT_DIR}/TranslatorX.pl -i {input} -o {output} -p M -t F -w 1 -c 5"


rule trim_seqIDs_to_taxon:
    input:
        "output/{og}.aln.fa"
    output:
        "output/{og}.trID.aln.fa"
    conda:
        "../envs/perl.yaml"
    shell:
        "perl {SCRIPT_DIR}/seqID_taxon_only.pl {input} {output}"
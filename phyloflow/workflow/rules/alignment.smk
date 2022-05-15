rule mafft_aa:
    input:
        "data/{og}"
    output:
        "output/{og}.aln.fa"
    log:
        "logs/mafft/{og}.log"
    conda:
        "../envs/mafft.yaml"
    shell:
        "{{ mafft {input} > {output} ; }} &> {log}"


rule trim_seqIDs_to_taxon:
    input:
        "output/{og}.aln.fa"
    output:
        "output/{og}.trID.aln.fa"
    shell:
        "perl ext_scripts/seqID_taxon_only.pl {input} {output}"
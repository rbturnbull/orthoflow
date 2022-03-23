rule list_alignments:
    input:
        expand("output/{og}.trID.aln.fa",og=ogs)
    output:
        "output/phykit_concat/files_to_concatenate.txt"
    shell:
        "ls -1 output/*.trID.aln.fa > {output}"

rule concatenate_alignments:
    input:
        "output/phykit_concat/files_to_concatenate.txt"
    output:
        "output/phykit_concat/concatenated"
    conda:
        "../envs/phykit.yaml"
    log:
        "logs/phykit_concat/concatenated.log"
    shell:
        "phykit create_concat -a {input} -p {output}"
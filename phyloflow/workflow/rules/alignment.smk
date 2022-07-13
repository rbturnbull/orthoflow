
def get_orthologs_path(wildcards):
    orthologs_checkpoint = checkpoints.orthofisher_filtered if config.get('use_orthofisher', False) else checkpoints.orthofinder_all
    orthologs_path = orthologs_checkpoint.get(**wildcards).output[0]
    return orthologs_path


def get_alignment_inputs(wildcards):
    """
    Gets the results of one of the orthologs modules to pass to the alignment.
    """
    return f"{get_orthologs_path(wildcards)}/{{og}}.fa"


rule mafft:
    """
    Aligns the protein (amino acid) ortholog with MAFFT.
    """
    input:
        get_alignment_inputs
    output:
        "results/alignment/aligned_proteins/{og}.alignment.fa"
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

rule get_cds_seq:
    """
    This rule creates an unaligned mfasta file of the corresponding nucleotide sequences.

    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    input:
        cds_dir=Path(rules.add_taxon.output[0]).parent,
        alignment=rules.mafft.output
    output:
        "results/alignment/seqs_cds/{og}.seqs.cds.fa"
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    shell:
        "python {SCRIPT_DIR}/get_cds_seq.py --cds-dir {input.cds_dir} --alignment {input.alignment} --output-file {output}"


rule taxon_only:
    """
    Trim sequence IDs to taxon.

    At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier
    and produce clean output for the next stages.
    """
    input:
        rules.mafft.output
    output:
        "results/alignment/taxon_only/{og}.alignment.taxon_only.protein.fa"
    conda:
        "../envs/typer.yaml"
    shell:
        "python {SCRIPT_DIR}/taxon_only.py {input} {output}"


rule thread_dna:
    """
    Back-translates the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#protein-to-nucleotide-alignment

    The --stop argument keeps in stop codons which are otherwise removed.
    """
    input:
        alignment=rules.taxon_only.output,
        cds=rules.get_cds_seq.output
    output:
        "results/alignment/threaded_cds/{og}.alignment.cds.fa"
    bibs:
        "../bibs/phykit.bib"
    conda:
        "../envs/phykit.yaml"
    shell:
        """
        phykit thread_dna --protein {input.alignment} --nucleotide {input.cds} --stop > {output}
        """


def list_cds_alignments(wildcards):
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    return expand(rules.thread_dna.output, og=all_ogs)


def list_protein_alignments(wildcards):
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    return expand(rules.taxon_only.output, og=all_ogs)


def list_alignments(wildcards):
    if config.get("infer_tree_with_protein_seqs", True):
        return list_protein_alignments(wildcards)
    return list_cds_alignments(wildcards)

# TODO add alignment trimming


rule list_alignments:
    """
    List path to alignment files into a single text file for use in PhyKIT.

    If the `infer_tree_with_protein_seqs` config variable is True, then it uses the protein alignments
    otherwise it uses the threaded CDS sequences.

    :config: infer_tree_with_protein_seqs
    """
    input:
        list_alignments
    output:
        "results/alignment/alignments.txt",
    shell:
        """
        ls -1 {input} > {output}
        """

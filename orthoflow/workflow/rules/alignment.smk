from Bio import AlignIO


infer_tree_with_protein_seqs = config.get("infer_tree_with_protein_seqs", INFER_TREE_WITH_PROTEIN_SEQS_DEFAULT)
alignment_type = "protein" if infer_tree_with_protein_seqs else "cds"

def get_orthologs_path(wildcards):
    orthologs_checkpoint = checkpoints.min_seq_filter_orthofisher if config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT) else checkpoints.orthofinder_all
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
        "results/alignment/aligned_proteins/{og}.protein.alignment.fa"
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
        ENV_DIR / "mafft.yaml"
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
        "results/alignment/seqs_cds/{og}.cds.seqs.fa"
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    shell:
        "python {SCRIPT_DIR}/get_cds_seq.py --cds-dir {input.cds_dir} --alignment {input.alignment} --output-file {output}"


checkpoint taxon_only:
    """
    Trim sequence IDs to taxon.

    At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier
    and produce clean output for the next stages.
    """
    input:
        rules.mafft.output
    output:
        f"results/alignment/taxon_only/{{og}}.taxon_only.{alignment_type}.alignment.fa"
    conda:
        ENV_DIR / "typer.yaml"
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
        "results/alignment/threaded_cds/{og}.cds.alignment.fa"
    bibs:
        "../bibs/phykit.bib"
    conda:
        ENV_DIR / "phykit.yaml"
    shell:
        """
        phykit thread_dna --protein {input.alignment} --nucleotide {input.cds} --stop > {output}
        """

checkpoint trim_alignments:
    """
    Trim multiple-sequence alignments using ClipKIT.

    https://jlsteenwyk.com/ClipKIT
    """
    input:
        rules.taxon_only.output if infer_tree_with_protein_seqs else rules.thread_dna.output,
    output:
        f"results/alignment/trimmed/{{og}}.trimmed.{alignment_type}.alignment.fa"
    bibs:
        "../bibs/clipkit.bib"
    conda:
        ENV_DIR / "clipkit.yaml"
    shell:
        """
        clipkit {input} -m smart-gap -o {output}
        """


def filter_alignments(untrimmed_alignments, trimmed_alignments, min_length, max_trimmed_proportion):
    """
    Returns a list of alignements which have a minimum length and the proportion of sites retained after trimming.
    """
    filtered = []
    for untrimmed_alignment_path, trimmed_alignment_path in zip(untrimmed_alignments, trimmed_alignments):
        trimmed_length = AlignIO.read(trimmed_alignment_path, "fasta").get_alignment_length()
        if trimmed_length < min_length:
            continue

        untrimmed_length = AlignIO.read(untrimmed_alignment_path, "fasta").get_alignment_length()
        if trimmed_length > max_trimmed_proportion * untrimmed_length:
            filtered.append(trimmed_alignment_path)
    
    filtered = sorted(filtered)
    return filtered


def list_cds_alignments(wildcards):
    """
    Returns a list of all the trimmed CDS alignments which have a minimum length and the proportion of sites retained after trimming.
    """
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    for og in all_ogs:
        checkpoints.trim_alignments.get(og=og)
    return filter_alignments(
        untrimmed_alignments=expand(rules.thread_dna.output, og=all_ogs),
        trimmed_alignments=expand(rules.trim_alignments.output, og=all_ogs),
        min_length=config.get("minimum_trimmed_alignment_length_cds", MINIMUM_TRIMMED_ALIGNMENT_LENGTH_CDS_DEFAULT),
        max_trimmed_proportion=config.get("max_trimmed_proportion", MAX_TRIMMED_PROPORTION_DEFAULT),
    )


def list_protein_alignments(wildcards):
    """
    Returns a list of all the trimmed protein alignments which have a minimum length and the proportion of sites retained after trimming.
    """
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    for og in all_ogs:
        checkpoints.trim_alignments.get(og=og)
    return filter_alignments(
        untrimmed_alignments=expand(rules.taxon_only.output, og=all_ogs),
        trimmed_alignments=expand(rules.trim_alignments.output, og=all_ogs),
        min_length=config.get("minimum_trimmed_alignment_length_proteins", MINIMUM_TRIMMED_ALIGNMENT_LENGTH_PROTEINS_DEFAULT),
        max_trimmed_proportion=config.get("max_trimmed_proportion", MAX_TRIMMED_PROPORTION_DEFAULT),
    )


def get_alignments(wildcards):
    """
    Chooses either the protein or CDS alignments depending on the infer_tree_with_protein_seqs setting in the config.
    """
    if infer_tree_with_protein_seqs:
        return list_protein_alignments(wildcards)
    return list_cds_alignments(wildcards)


rule list_alignments:
    """
    List path to alignment files into a single text file for use in PhyKIT.

    :config infer_tree_with_protein_seqs: If the `infer_tree_with_protein_seqs` config variable is True, then it uses the protein alignments otherwise it uses the threaded CDS sequences.
    """
    input:
        get_alignments
    output:
        f"results/alignment/alignments_list.{alignment_type}.txt",
    shell:
        """
        ls -1 {input} > {output}
        """

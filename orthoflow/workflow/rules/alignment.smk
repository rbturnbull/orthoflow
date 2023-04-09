

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
        LOG_DIR / "alignment/mafft/mafft-{og}.log"
    threads: 4
    resources:
        time="00:10:00",
        mem="8G",
        cpus=4,
    conda:
        ENV_DIR / "mafft.yaml"
    shell:
        """
        {{ mafft --thread {threads} --auto {input} > {output} ; }} &> {log}
        """


rule get_cds_seq:
    """
    This rule creates an unaligned mfasta file of the corresponding nucleotide sequences.

    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    input:
        cds_dir=Path(rules.extract_cds.output[0]).parent,
        alignment=rules.mafft.output
    output:
        "results/alignment/seqs_cds/{og}.cds.seqs.fa"
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
    log:
        LOG_DIR / "alignment/get_cds_seq/{og}.log"
    shell:
        """
        python {SCRIPT_DIR}/get_cds_seq.py --cds-dir {input.cds_dir} --alignment {input.alignment} --output-file {output}
        """
        # "python {SCRIPT_DIR}/get_cds_seq.py --cds-dir {input.cds_dir} --alignment {input.alignment} --output-file {output} &> {log}"


rule taxon_only:
    """
    Trim sequence IDs to taxon.

    At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier
    and produce clean output for the next stages.
    """
    input:
        rules.mafft.output
    output:
        "results/alignment/taxon_only/{og}.taxon_only.protein.alignment.fa"
    conda:
        ENV_DIR / "typer.yaml"
    log:
        LOG_DIR / "alignment/taxon_only/{og}.log"
    shell:
        "python {SCRIPT_DIR}/taxon_only.py {input} {output} &> {log}"


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
    log:
        LOG_DIR / "alignment/thread_dna/{og}.log"
    shell:
        """
        {{ phykit thread_dna --protein {input.alignment} --nucleotide {input.cds} --stop > {output} ; }} &> {log}
        """


def get_alignments_to_trim(wildcards):
    if wildcards.alignment_type == "cds":
        return rules.thread_dna.output

    return rules.taxon_only.output


rule trim_alignments:
    """
    Trim multiple-sequence alignments using ClipKIT.

    https://jlsteenwyk.com/ClipKIT
    """
    input:
        get_alignments_to_trim
    output:
        "results/alignment/trimmed_{alignment_type}/{og}.trimmed.{alignment_type}.alignment.fa"
    bibs:
        "../bibs/clipkit.bib"
    conda:
        ENV_DIR / "clipkit.yaml"
    log:
        LOG_DIR / "alignment/trim_alignments/{og}.{alignment_type}.log"
    shell:
        """
        clipkit {input} -m smart-gap -o {output} &> {log}
        """


def get_trimmed_alignments(wildcards):
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    return expand(rules.trim_alignments.output, og=all_ogs, alignment_type=wildcards.alignment_type)


def get_untrimmed_alignments(wildcards):
    orthologs_path = get_orthologs_path(wildcards)
    all_ogs = glob_wildcards(os.path.join(orthologs_path, "{og}.fa")).og
    if wildcards.alignment_type == "cds":
        return expand(rules.thread_dna.output, og=all_ogs) 
    return expand(rules.taxon_only.output, og=all_ogs)


def get_min_length(wildcards):
    if wildcards.alignment_type == "cds":
        return config.get("minimum_trimmed_alignment_length_cds", MINIMUM_TRIMMED_ALIGNMENT_LENGTH_CDS_DEFAULT)

    return config.get("minimum_trimmed_alignment_length_proteins", MINIMUM_TRIMMED_ALIGNMENT_LENGTH_PROTEINS_DEFAULT)


checkpoint list_alignments:
    """
    List path to alignment files into a single text file for use in PhyKIT.
    """
    input:
        trimmed=get_trimmed_alignments,
        untrimmed=get_untrimmed_alignments,
    output:
        "results/alignment/alignments_list.{alignment_type}.txt",
    params:
        min_length=get_min_length,
        max_trimmed_proportion=config.get("max_trimmed_proportion", MAX_TRIMMED_PROPORTION_DEFAULT),
    threads: workflow.cores
    log:
        LOG_DIR / "alignment/list_alignments.{alignment_type}.log"
    script:
        f"{SCRIPT_DIR}/filter_alignments.py"

def list_filtered(wildcards):
    alignments_text_file = checkpoints.list_alignments.get(**wildcards).output[0]
    alignments = Path(alignments_text_file).read_text().strip().split("\n")

    if len(alignments[0]) == 0:
        raise EOFError(f"No {wildcards.alignment_type} alignments present after filtering.\nCheck input or change minimum_trimmed_alignment_length_{wildcards.alignment_type} or max_trimmed_proportion")

    return alignments_text_file

checkpoint check_presence_after_filtering:
    input:
        list_filtered
    output:
        "results/alignment/alignments_list_present.{alignment_type}.txt",
    shell:
        "cat {input} > {output} && [[ -s {output} ]]"



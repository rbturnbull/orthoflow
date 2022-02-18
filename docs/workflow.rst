========
Workflow
========

.. graphviz::

    digraph workflow {
        exome [label="Exome data"];
        transcriptome [label="Transcriptome data\n(pre-assembled)"];
        addotated [label="Annotated genomes\n(.gb)"];
        cds [label="CDS collection"];
        gene [label="gene clusters"];
        scog [label="SC-OG"];
        snap [label="SNAP-OG"];
        unaligned [label="Unaligned genes\n(AA & NT)"];
        genealignments [label="Gene alignments\n(AA & NT)"];
        filtered [label="Filtered alignments\n(AA & NT)"];
        supermatrix [label="Supermatrix\n(AA & NT)"];
        phy1 [label="Phylogeny 1"];
        genetrees [label="Gene Trees\n(AA &/or NT)"];
        phy2 [label="Phylogeny 2"];

        exome -> cds;
        transcriptome -> cds;
        addotated -> cds;
        cds -> gene;
        gene -> scog;
        gene -> snap;
        scog -> unaligned;
        snap -> unaligned;
        unaligned -> genealignments;
        genealignments -> filtered;
        filtered -> supermatrix;
        supermatrix -> phy1;
        filtered -> genetrees;
        genetrees -> phy2;
    }

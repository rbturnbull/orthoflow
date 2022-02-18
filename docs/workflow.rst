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
        
        subgraph cluster_1 {
            node [style=filled];
            exome -> cds;
            transcriptome -> cds;
            addotated -> cds;
            label = "Data Intake";
            color=purple
        }
        subgraph cluster_2 {
            node [style=filled];
            gene -> scog;
            gene -> snap;
            label = "Orthologs Module";
            color=green
        }
        subgraph clusteralignment {
            node [style=filled];
            unaligned -> genealignments;
            genealignments -> filtered;
            label = "Alignment Module";
            color=blue
        }
        subgraph clustersupermatrix {
            node [style=filled];
            supermatrix -> phy1;
            label = "Supermatrix Module";
            color=orange
        }
        subgraph clustergenetree {
            node [style=filled];
            genetrees -> phy2;
            label = "Genetree and Reconciliation Module";
            color=red
        }

        cds -> gene;
        scog -> unaligned;
        snap -> unaligned;
        filtered -> supermatrix;
        filtered -> genetrees;
    }

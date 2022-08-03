===========================
PhyloFlow Advanced Tutorial
===========================


Changing workflow settings
==========================

Some workflow settings can be changed by passing arguments to the command-line tool (``phyloflow``). Perhaps the most important one is ``--cores`` to specify the number of cores for the workflow to use. To see a complete list of command-line arguments, run:

.. code-block::

    phyloflow --help

You can pass any snakemake arguments to phyloflow. To list these, run:

.. code-block::

    phyloflow --help-snakemake 

Most settings to operate and tune aspects of the workflow can be changed by editing the standard configuration file (``phyloflow/config/config.yml``) or writing a custom configuration file that can be passed to the workflow. You will see examples of changes to the configuration file throughout this tutorial.


Input and output paths
======================

To use a specific target file with input sources, give that as an argument:

.. code-block::

    phyloflow path/to/target/input-sources-file

To set a working directory different to the current directory, use the `--directory` flag:

.. code-block::

    phyloflow --directory path/to/working/dir



Controlling the flow of operations
==================================

By default, PhyloFlow uses the *de novo* orthology inference module (OrthoFinder and OrthoSNAP) and supermatrix-based tree inference (supermatrix module).

![](../_static/diagram.png)

This can be changed in the configuration file. Setting the ``use_orthofisher`` to ``True`` will enable the ortholog fishing module instead of the *de novo* orthology inference module. This also requires you to specify a set of HMM profiles listed under ``orthofisher_hmmer_files``. For example:

.. code-block::

    use_orthofisher: True
    orthofisher_hmmer_files:
    - hmms/1080at3041.hmm
    - hmms/1103at3041.hmm
    - hmms/1271at3041.hmm
    - hmms/1379at3041.hmm
    - hmms/1518at3041.hmm
    - hmms/1569at3041.hmm
    - hmms/1610at3041.hmm

To use the Gene Tree and Reconciliation (ASTRAL) path for tree inference, **ADD INSTRUCTIONS /// ALSO, DO WE ALLOW BOTH TO RUN IN ONE EXECUTION OR SHOULD USER RE-LAUNCH WITH DIFFERENT SETTINGS. WRITE INSTRUCTIONS**


Gene filtering settings
=======================

There are several steps in the workflow that filter out genes not meeting particular criteria. 

Minimum taxa
------------
One important setting is the minimum number of taxa that need to be in a gene dataset in order for it to be retained. This can be set with the ``ortholog_min_seqs`` setting in the configuration file. The default value is 5. The occupancy setting for OrthoSNAP can be changed with ``orthosnap_occupancy``; by default we use the same value as that for ``ortholog_min_seqs``.

Using SC-OGs and/or SNAP-OGs
----------------------------
The traditional approach towards inferring species trees from genome data is to select single-copy orthogroups (SC-OGs). One of the innovations we've implemented in this workflow is the use of SNAP-OGs, sets of orthologous sequences derived from multi-copy gene families, which can yield orders of magnitude more data. You can set whether you want to build a phylogeny from just the SC-OGs, just the SNAP-OGs or both combined by setting the ``use_scogs`` and ``use_snap_ogs`` in the configuration file. In this example both SC-OGs and SNAP-OGs are combined for phylogenetic inference:

.. code-block::

    use_scogs: True
    use_snap_ogs: True

SNAP-OGs are currently only implemented in the *de novo* ortholog analysis path. When using the ortholog fishing path, only SC-OGs will be used for downstream analyses.

Removal of heavily trimmed alignments
-------------------------------------
In some cases, it may make more sense to remove genes that have been decimated by the alignment trimming proceduce, particularly if they are going to be used individually to infer gene trees. **COMPLETE HERE HOW TO CHANGE THESE SETTINGS**



Alignment trimming settings
===========================
**TO BE WRITTEN**


Tree inference settings
=======================

An important choice to make is whether to run the phylogenetic analysis on protein or nucleotide sequences. This can be set in the configuration file ``infer_tree_with_protein_seqs``. The default setting (``True``) is to use protein sequences.

To use an outgroup in the phylogenetic analysis, specify an outgroup taxon (using its value in the ``taxon_string`` column in the input sources file). For example, for the demonstration dataset:

.. code-block::

    outgroup: "Derbesia_sp_WEST4838"

**ADD MORE TREE INFERENCE DETAILS HERE -- SOME TOPICS BELOW**
Bootstrap types
Model specification / testing -- we're just passing the ``-m`` flag => user can pass in ``TEST`` for model testing or any of the IQtree model names (<https://www.iqtree.org/doc/Command-Reference#specifying-substitution-models>)


Other topics ????
=================

- running on HPC (but perhaps this can go in the installation instructions instead, as it's mostly setup/configuration)
- 

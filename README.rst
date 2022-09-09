======================
Orthoflow
======================

.. image:: https://raw.githubusercontent.com/rbturnbull/orthoflow/master/docs/_static/images/orthoflow-banner.svg

.. start-badges

|pipeline badge| |docs badge| |black badge| |snakemake badge| |git3moji badge| |contributor covenant badge|

.. |pipeline badge| image:: https://github.com/rbturnbull/orthoflow/actions/workflows/testing.yml/badge.svg
    :target: https://rbturnbull.github.io/orthoflow

.. |docs badge| image:: https://github.com/rbturnbull/orthoflow/actions/workflows/docs.yml/badge.svg
    :target: https://rbturnbull.github.io/orthoflow/
    
.. |black badge| image:: https://img.shields.io/badge/code%20style-black-000000.svg
    :target: https://github.com/psf/black

.. |snakemake badge| image:: https://img.shields.io/badge/snakemake-≥5.6.0-brightgreen.svg?style=flat
    :target: https://snakemake.readthedocs.io

.. |git3moji badge| image:: https://img.shields.io/badge/git3moji-%E2%9A%A1%EF%B8%8F%F0%9F%90%9B%F0%9F%93%BA%F0%9F%91%AE%F0%9F%94%A4-fffad8.svg
    :target: https://robinpokorny.github.io/git3moji/

.. |contributor covenant badge| image:: https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg
    :target: CONTRIBUTING.html#code-of-conduct

.. end-badges

Orthoflow is a workflow for phylogenetic inference of genome-scale datasets of protein-coding genes. 
Our goal was to make it straightforward to work from a combination of input sources including annotated contigs in Genbank format and FASTA files containing CDSs.
It uses several state of the art inference methods for orthology inference, either based on HMM profiles or de novo inference of orthogroups.
Through the use of OrthoSNAP, many additional ortholog alignments can be generated from multi-copy gene families.
For phylogenetic inference, users can choose a supermatrix approach and/or gene tree inference followed by supertree reconstruction.
Users can specify a range of alignment filtering settings to retain high-quality alignments for phylogenetic inference.
The workflow produces a detailed report that, in addition to the phylogenetic results, includes a range of diagnostics to verify the quality of the results.


.. image:: docs/source/_static/images/orthoflow-workflow-diagram.svg

Documentation
=============

Detailed documentation can be found at https://rbturnbull.github.io/orthoflow/


.. start-beginner-tutorial

=================
Quick start guide
=================

Input data
==========

Orthoflow works from an input CSV file with information about the data sources  to be used. Preparing this file is central to setting up your run. The default filename for this is ``input_sources.csv``.

It needs the columns ``file``, ``taxon_string``, ``data_type`` and ``translation_table``.

- The ``file`` column is the path to the file relative to the working directory.
- The ``taxon_string`` is the name of the taxon from which the data was obtained.
- The ``data_type`` column should be either `CDS` when providing a FASTA file with coding sequences, or ``GenBank`` when providing a GenBank-formatted file with CDS annotations.
- The ``translation_table`` column should have the translation table (genetic code) number for the data as given `here <https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c>`_.

Let's look at the demonstration dataset distributed with the code: ``tests/test-data/input_sources.csv``.

=================== ================================== ========== =================
file                taxon_string                       data_type  translation_table
=================== ================================== ========== =================
KY509313.gb         Avrainvillea_mazei_HV02664         GenBank    11
NC_026795.txt       Bryopsis_plumosa_WEST4718          GenBank    11
KX808498.gb         Caulerpa_cliftonii_HV03798         GenBank    11
KY819064.cds.fasta  Chlorodesmis_fastigiata_HV03865    CDS        11
KX808497.fa         Derbesia_sp_WEST4838               CDS        11
MH591079.gb         Dichotomosiphon_tuberosus_HV03781  GenBank    11
MH591080.gbk        Dichotomosiphon_tuberosus_HV03781  GenBank    11
MH591081.gbk        Dichotomosiphon_tuberosus_HV03781  GenBank    11
MH591083.gb         Flabellia_petiolata_HV01202        GenBank    11
MH591084.gb         Flabellia_petiolata_HV01202        GenBank    11
MH591085.gb         Flabellia_petiolata_HV01202        GenBank    11
MH591086.gb         Flabellia_petiolata_HV01202        GenBank    11
=================== ================================== ========== =================

We are using a dataset of algal chloroplast genomes, some as annotated genbank files (``data_type: Genbank``), some as fasta files of the coding sequences (``data_type: CDS``). They all use the bacterial genetic code (``translation_table: 11``). Some of the genomes were in a single Genbank file (e.g. ``KY09313.gb`` at the top), others were fragmented across multiple files (e.g. last 4 all belonging to the same taxon).

The ``taxon_string`` column is perhaps the most important one, as these will be the names to appear in the output tree and this determines how input data gets grouped (e.g. all CDSs in the final four GenBank files will be grouped into a single taxon). In this case, we have included specimen numbers as part of the taxon string but that is optional.



Simple run
==========

We are using the small demonstration dataset distributed with the Orthoflow in the ``tests/test-data`` subdirectory.

Go into the directory containing the ``input_sources.csv`` file and run orthoflow with default settings with these commands:

.. code-block::

    cd tests/test-data
    orthoflow

By default, Orthoflow will extract the CDSs from the input files, run OrthoFinder followed by OrthoSNAP to determine orthologous genes, align them and infer a concatenated tree from the protein sequences. You can follow progress on the screen as the workflow executes and outputs are produced.

Note that the first time you run the workflow, it will be slow because it needs to download and install the software it depends on. This is a one-time thing and runs should get going much faster after.


Examining the output
====================

Inferred tree and intermediate files
------------------------------------
All output files are saved in the ``results`` directory. Output files are subdivided into the workflow modules, which each have their own subdirectory. For the demonstration analysis that we ran above, the inferred phylogeny will be in the ``supermatrix`` subdirectory and be called ``supermatrix.protein.fa.treefile``. Open this with a tree browser (e.g. `FigTree <https://github.com/rambaut/figtree>`_). Also take some time to browse the intermediary files, including the orthogroups, gene alignments and the supermatrix constructed from them.

Report and diagnostics
----------------------
The report provides an overview of the results, the analysis settings used and citations of the software used to produce the results. This report is found in the ``results/report.html``

Output logs
-----------
The output logs of all software used as part of the workflow can be found in the ``logs`` directory.

.. end-beginner-tutorial


Credits and Attribution
========================

.. start-credits

Orthoflow was created by Robert Turnbull, Jacob Steenwyk, Simon Mutch, Vinícius Salazar, and Heroen Verbruggen.

Citation details to follow.

.. end-credits
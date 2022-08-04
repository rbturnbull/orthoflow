=============================
PhyloFlow Beginner's Tutorial
=============================

Input data
==========

PhyloFlow works from an input CSV file with information about the data sources  to be used. Preparing this file is central to setting up your run. The default filename for this is ``input_sources.csv``.

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

We are using the small demonstration dataset distributed with the PhyloFlow in the ``tests/test-data`` subdirectory.

Go into the directory containing the ``input_sources.csv`` file and run phyloflow with default settings with these commands:

.. code-block::

    cd tests/test-data
    phyloflow

By default, PhyloFlow will extract the CDSs from the input files, run OrthoFinder followed by OrthoSNAP to determine orthologous genes, align them and infer a concatenated tree from the protein sequences. You can follow progress on the screen as the workflow executes and outputs are produced.

Note that the first time you run the workflow, it will be slow because it needs to download and install the software it depends on. This is a one-time thing and runs should get going much faster after.


Examining the output
====================

Inferred tree and intermediate files
------------------------------------
All output files are saved in the ``results`` directory. Output files are subdivided into the workflow modules, which each have their own subdirectory. For the demonstration analysis that we ran above, the inferred phylogeny will be in the ``supermatrix`` subdirectory and be called ``supermatrix.fa.treefile``. Open this with a tree browser (e.g. `FigTree <https://github.com/rambaut/figtree>`_). Also take some time to browse the intermediary files, including the orthogroups, gene alignments and the supermatrix constructed from them.

Report and diagnostics
----------------------
The report provides a comprehensive overview of the results, the analysis settings used and citations of the software used to produce the results. **THIS CAN BE FOUND WHERE??**

**EDUCATE USERS ABOUT THE DIAGNOSTICS**

Output logs
-----------
The output logs of all software used as part of the workflow can be found in the ``logs`` directory.

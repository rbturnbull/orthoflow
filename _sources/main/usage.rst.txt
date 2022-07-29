============
Usage
============


After installing, you need to create an input file for phyloflow to use. 
The default name for this file is `input_sources.csv` but this can be changed in the `configuration <configuration.html>`_ file.

The file looks something like this:

.. csv-table:: input_sources.csv
   :file: ../../../tests/test-data/input_sources.csv
   :widths: 30, 30, 30, 30
   :header-rows: 1

It needs the columns `file`, `taxon_string`, `data_type` and `translation_table`. 
The `file` column is the path to the file relative to the working directory.
The `taxon_string`, is the name of the taxon in the file.
The `data_type` column must be `CDS` or `GenBank`, `gb`, or `gbk` (case insensitive).
The `translation_table` is integer id of the translation table to translated coding sequences to amino acid sequences using 
`BioKIT <https://jlsteenwyk.com/BioKIT/usage/index.html#translate-sequence>`_. 
See the `list of genetic codes published by the NCBI <https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c>`_.

Once this file is created and stored in the current working directory, run phyloflow with the command:

.. code-block::bash

    phyloflow

To set a specific target file to generate, give that as an argument:

.. code-block::bash

    phyloflow path/to/target/file

To set a working directory different to the current directory, use the `--directory` flag:

.. code-block::bash

    phyloflow --directory path/to/working/dir


Demonstration Data
==================

In the repository is a set of demonstration data. 
There are already input DNA sequence files and an `input_sources.csv` which is the same as the table above.
To run it, go into the test-data directory and run phyloflow:

.. code-block::bash

    cd tests/test-data
    phyloflow


HPC
====

HOW TO RUN WITH SLURM
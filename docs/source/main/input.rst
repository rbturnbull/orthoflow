===========
Input
===========

The default input filename expected by Orthoflow is ``input_sources.csv``. 
This default filename can be set in the config:

.. code-block:: yaml

    input_sources: "input_sources2.csv"

This default can be overridden in the command line arguments for orthoflow:

.. code-block:: bash

    orthoflow --files input_sources3.csv

For the analysis to work, Orthoflow requires the following information for each input source:

- ``file``: The path to the particular input source file. This is path is relative to whatever file lists this source file.
- ``taxon_string``: A name for the taxon which is associated with all the sequences in the input file. If this value is not given then, the taxon string will be taken from the organism specified in the metadata of the source file if it is in GenBank format or it will be taken from the filename if it is not.
- ``translation_table``: For each input file, the user can give the translation table number which corresponds with the `NCBI genetic codes <https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes>`_. If it is not given, then Orthoflow looks in the GenBank file for a translation table otherwise it uses the ``default_translation_table`` config variable (which by default is set to 1).
- ``data_type``: To indicate the format of the file. This column should be ``GenBank`` when providing a GenBank-formatted file with CDS annotations, or ``CDS`` or ``Protein`` when providing a FASTA file with coding sequences consisting of nucleotides or amino acids respectively.

All this input information can be explicitly stated in a CSV file. Like this:

.. csv-table:: input_sources.csv
   :file: ../../../tests/test-data/input_sources.csv
   :header-rows: 1

This file can also be given in YAML format:

.. literalinclude :: ../../../tests/test-data/input_sources.yml
   :language: yaml

Or TOML:

.. literalinclude :: ../../../tests/test-data/input_sources.toml
   :language: toml


Or JSON:

.. literalinclude :: ../../../tests/test-data/input_sources.json
   :language: json

Since some of the values can be inferred from the files themselves, the ame input can be specified more concisely as follows (here in YAML format):

.. literalinclude :: ../../../tests/test-data/input_sources.concise.yml
   :language: yaml

The ``input_sources`` can also be a list of files. For example, this command will include all the GenBank files in a particular directory and the translation_table, taxon_string, and data_type will all be inferred from the files themselves:

.. code-block:: bash

    orthoflow --files *.gb

If some of the input files are in Fasta format and so the translation table is not easily inferred, then you can create an individal TOML/YAML/JSON or CSV file for that input source like this:

.. literalinclude :: ../../../tests/test-data-small/tests/test-data-small/KY819064-truncated.cds.toml
   :language: toml

Then these files can be included as part of the list of Orthoflow input sources:

.. code-block:: bash

    orthoflow --files *.gb *.toml

It is possible to ignore files that are not valid. The default setting is to stop the workflow when a file does not meet the program requirements. When it is desired that the program ignores these non-valid files and analysises the other files ``ignore_non_valid_files`` can be set to ``True``. A warning will be displayed in the report stating which files have been ignored.
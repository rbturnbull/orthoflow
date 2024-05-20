======================================================
Plant Tutorial
======================================================

This tutorial shows you how to run the '1KP Pilot' study in Orthoflow.
The dataset contains 103 plant transcriptomes (`PRJEB4921 <https://www.ncbi.nlm.nih.gov/bioproject/PRJEB4921/>`_):

    Matasci, N., Hung, LH., Yan, Z. et al. Data access for the 1,000 Plants (1KP) project. GigaSci 3, 17 (2014). https://doi.org/10.1186/2047-217X-3-17

Phylogenomic analysis of this dataset was presented in:

    Wickett, Norman J., Siavash Mirarab, Nam Nguyen, Tandy Warnow, et al. 
    A phylotranscriptomic analysis of the origin and early diversification of land plants. 
    Proceedings of the National Academy of Sciences (PNAS), 111, no. 45 (2014): E4859–4868. doi:10.1073/pnas.1323926111.

Preparation
===================================

Download the input file for the dataset from our documentation at https://rbturnbull.github.io/orthoflow/_data/onekp_pilot.csv

.. code-block:: bash

    wget https://rbturnbull.github.io/orthoflow/_data/onekp_pilot.csv

This contains a CSV file that looks like this:

.. literalinclude :: ../_static/data/onekp_pilot.csv
    :language: csv
    :lines: 1-20

That CSV file contains a column with the URLs to the transcriptomes.

Use a bash script to download the files:

.. code-block:: bash

    #!/bin/bash

    for ROW in `tail -n +2 onekp_pilot.csv` ; do
        URL=$(echo $ROW | cut -f4 -d,)
        FILE=$(echo $ROW | cut -f3 -d,)
        echo $FILE
        [[ -f $FILE ]] || wget $URL -O $FILE


Now, let's set up the configuration file for Orthoflow. We only need to set the parameters which are different from the default values.

.. code-block:: yaml

    input_sources: "onekp_pilot.csv" # Alternatively this can be specified on the command line with --files onekp_pilot.csv
    infer_tree_with_cds_seqs: False # We are using protein sequences
    supermatrix: True
    supertree: True
    ortholog_min_seqs: 15  # Minimum number of sequences that needs to be in an alignment for it to proceed to phylogenetic analysis.
    ortholog_min_taxa: 15  # Minimum number of taxa that needs to be in an orthogroup.

Save this file to ``config_onekp_pilot.yaml``.

Running Orthoflow
=================

Phylogenomic analysis of this dataset can then be run with the command:

.. code-block:: bash

    orthoflow --configfile config_onekp_pilot.yaml


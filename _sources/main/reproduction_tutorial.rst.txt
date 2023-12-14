===========================
Reproduction Tutorial
===========================

This tutorial is a step-by-step guide to reproduce the results of the `paper <https://www.researchsquare.com/article/rs-3699210>`_.

Downloading the data
====================

The dataset used in the paper is available at figshare:

    Shen, Xing-Xing (2018). Tempo and mode of genome evolution in the budding yeast subphylum. figshare. Dataset. https://doi.org/10.6084/m9.figshare.5854692.v1

The data can be downloaded and extracted with this command:

.. code-block:: bash

    wget https://ndownloader.figshare.com/files/13092791 -O 0_332yeast_genomes.zip
    unzip 0_332yeast_genomes.zip
    cd 0_332yeast_genomes
    unzip 332_genome_annotations.zip
    cd pep

Setup
===============

You can create the input file for the 24 species shown in the paper but saving this text as ``yeast24.csv``:

.. code-block:: csv

    file,data_type
    ambrosiozyma_kashinagacola.max.pep,Protein
    ambrosiozyma_monospora.max.pep,Protein
    ascoidea_asiatica.max.pep,Protein
    ascoidea_rubescens.max.pep,Protein
    candida_auris.max.pep,Protein
    clavispora_lusitaniae.max.pep,Protein
    cyberlindnera_jadinii.max.pep,Protein
    cyberlindnera_fabianii_JCM3601.max.pep,Protein    
    eremothecium_cymbalariae.max.pep,Protein
    eremothecium_gossypii.max.pep,Protein
    hanseniaspora_uvarum.max.pep,Protein
    hanseniaspora_valbyensis.max.pep,Protein
    kluyveromyces_lactis.max.pep,Protein
    kluyveromyces_marxianus.max.pep,Protein
    lachancea_nothofagi.max.pep,Protein
    lachancea_quebecensis.max.pep,Protein
    metschnikowia_hibisci.max.pep,Protein
    metschnikowia_shivogae.max.pep,Protein
    ogataea_methanolica.max.pep,Protein
    ogataea_parapolymorpha.max.pep,Protein
    ogataea_polymorpha.max.pep,Protein
    saccharomycopsis_malanga.max.pep,Protein
    wickerhamomyces_anomalus.max.pep,Protein
    wickerhamomyces_ciferrii.max.pep,Protein    


Running Orthoflow
=================

The following command will run Orthoflow with the default parameters:

.. code-block:: bash

    orthoflow --files yeast24.csv

The results will be saved in the ``results`` folder.

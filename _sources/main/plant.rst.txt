======================================================
Plant Tutorial
======================================================

This tutorial shows you how to run the '1KP Pilot' study in Orthoflow.
The dataset contains 103 plant transcriptomes (`PRJEB4921 <https://www.ncbi.nlm.nih.gov/bioproject/PRJEB4921/>`_):

    Matasci, N., Hung, LH., Yan, Z. et al. Data access for the 1,000 Plants (1KP) project. GigaSci 3, 17 (2014). https://doi.org/10.1186/2047-217X-3-17

Phylogenomic analysis of this dataset was presented in:

    Wickett, Norman J., Siavash Mirarab, Nam Nguyen, Tandy Warnow, et al. 
    A phylotranscriptomic analysis of the origin and early diversification of land plants. 
    Proceedings of the National Academy of Sciences (PNAS), 111, no. 45 (2014): E4859–4868. https://doi.org/10.1073/pnas.1323926111

Preparation
===================================

Download the input file for the dataset from our documentation at https://rbturnbull.github.io/orthoflow/_static/data/onekp_pilot.csv

.. code-block:: bash

    wget https://rbturnbull.github.io/orthoflow/_static/data/onekp_pilot.csv

This contains a CSV file where the first 20 lines looks like this:

.. code-block:: csv

    taxon_string,iPlant ID,file,url,data_type
    Arabidopsis_thaliana,,Arabidopsis_thaliana.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/735/GCF_000001735.4_TAIR10.1/GCF_000001735.4_TAIR10.1_protein.faa.gz,Protein
    Brachypodium_distachyon,,Brachypodium_distachyon.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/505/GCF_000005505.3_Brachypodium_distachyon_v3.0/GCF_000005505.3_Brachypodium_distachyon_v3.0_protein.faa.gz,Protein
    Carica_papaya,,Carica_papaya.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/150/535/GCF_000150535.2_Papaya1.0/GCF_000150535.2_Papaya1.0_protein.faa.gz,Protein
    Medicago_truncatula,,Medicago_truncatula.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/473/485/GCF_003473485.1_MtrunA17r5.0-ANR/GCF_003473485.1_MtrunA17r5.0-ANR_protein.faa.gz,Protein
    Oryza_sativa,,Oryza_sativa.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/433/935/GCF_001433935.1_IRGSP-1.0/GCF_001433935.1_IRGSP-1.0_protein.faa.gz,Protein
    Physcomitrella_patens,,Physcomitrella_patens.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/425/GCF_000002425.4_Phypa_V3/GCF_000002425.4_Phypa_V3_protein.faa.gz,Protein
    Populus_trichocarpa,,Populus_trichocarpa.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/775/GCF_000002775.5_P.trichocarpa_v4.1/GCF_000002775.5_P.trichocarpa_v4.1_protein.faa.gz,Protein
    Selaginella_moellendorffii,,Selaginella_moellendorffii.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/143/415/GCF_000143415.4_v1.0/GCF_000143415.4_v1.0_protein.faa.gz,Protein
    Sorghum_bicolor,,Sorghum_bicolor.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/003/195/GCF_000003195.3_Sorghum_bicolor_NCBIv3/GCF_000003195.3_Sorghum_bicolor_NCBIv3_protein.faa.gz,Protein
    Vitis_vinifera,,Vitis_vinifera.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/030/704/535/GCF_030704535.1_ASM3070453v1/GCF_030704535.1_ASM3070453v1_protein.faa.gz,Protein
    Zea_mays,,Zea_mays.faa.gz,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/902/167/145/GCF_902167145.1_Zm-B73-REFERENCE-NAM-5.0/GCF_902167145.1_Zm-B73-REFERENCE-NAM-5.0_protein.faa.gz,Protein
    ACFP-Boehmeria_nivea,ACFP,ACFP.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/ACFP-Boehmeria_nivea/translations/ACFP.faa,Protein
    ACOR-Acorus_americanus,ACOR,ACOR.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/ACOR-Acorus_americanus/translations/ACOR.faa,Protein
    AEKF-Penium_margaritaceum,AEKF,AEKF.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/AEKF-Penium_margaritaceum/translations/AEKF.faa,Protein
    AFQQ-Inula_helenium,AFQQ,AFQQ.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/AFQQ-Inula_helenium/translations/AFQQ.faa,Protein
    AMBO-Amborella_trichopoda,AMBO,AMBO.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/AMBO-Amborella_trichopoda/translations/AMBO.faa,Protein
    AQUI-Aquilegia_formosa,AQUI,AQUI.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/AQUI-Aquilegia_formosa/translations/AQUI.faa,Protein
    AZZW-Chlorokybus_atmophyticus,AZZW,AZZW.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/AZZW-Chlorokybus_atmophyticus/translations/AZZW.faa,Protein
    BFIK-Entransia_fimbriata,BFIK,BFIK.faa,https://de.cyverse.org/anon-files/iplant/home/shared/onekp_pilot/taxa/BFIK-Entransia_fimbriata/translations/BFIK.faa,Protein

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

    inputs: "onekp_pilot.csv" # Alternatively this can be specified on the command line with --inputs onekp_pilot.csv
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

    orthoflow run --configfile config_onekp_pilot.yaml


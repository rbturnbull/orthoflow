======================================================
One Thousand Plant Transcriptomes Tutorial
======================================================

This tutorial shows you how to run the 'One Thousand Plant Transcriptomes' (1KP) dataset in Orthoflow.

This is a dataset of more than 1000 plant transcriptomes for which phylogenomic analysis is presented in:

    One Thousand Plant Transcriptomes Initiative. 'One thousand plant transcriptomes and the phylogenomics of green plants.' *Nature* 574, 679–685 (2019). https://doi.org/10.1038/s41586-019-1693-2

Downloading and Input File Creation
===================================

You can download the list of species from CyVerse:

.. code-block:: bash

    wget https://de.cyverse.org/anon-files/iplant/home/shared/commons_repo/curated/oneKP_capstone_2019/transcript_assemblies/onekp_SRA.csv

That should download a file called ``onekp_SRA.csv`` to your current directory. The first few lines of the file should look like this:

.. code-block:: csv

    OneKP_ID,Accession,Species,NCBI Link
    ------------,-- -------------,-- ------------------------------,
    AALA,ERS1829210,Meliosma cuneifolia,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829210
    ABCD,ERS1830013,Racomitrium elongatum,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1830013
    ABEH,ERS1829580,Heliotropium greggii,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829580
    ABIJ,ERS1829938,Selaginella lepidophylla,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829938
    ABSS,ERS1829192,Sassafras albidum,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829192
    ACWS,ERS1829861,Agathis macrophylla,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829861
    ACYX,ERS1829232,Papaver rhoeas,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829232
    ADHK,ERS1829551,Galax urceolata,https://www.ncbi.nlm.nih.gov/sra/?term=ERS1829551    


To download the transcriptomes and create an input file for Orthoflow, you can use this bash script:

.. code-block:: bash

    mkdir -p downloads
    mkdir -p proteins
    echo "file,taxon_string,data_type" > input_sources_1kp.csv
    for DATA in $(tail -n +3 onekp_SRA.csv | sed 's/ /_/g'); do
        ID=$(echo $DATA | cut -d, -f1)
        echo $ID

        SPECIES=$(echo $DATA | cut -d, -f3 )
        ARCHIVE_NAME=${ID}-SOAPdenovo-Trans-translated.tar.bz2
        DOWNLOAD=downloads/$ARCHIVE_NAME
        URL=https://de.cyverse.org/anon-files/iplant/home/shared/commons_repo/curated/oneKP_capstone_2019/transcript_assemblies/${ID}-${SPECIES}/$ARCHIVE_NAME
        PROTEIN=proteins/$ID.prots.fasta

        # Download if necessary
        [[ -f $DOWNLOAD ]] || echo $URL

        if [ -f $DOWNLOAD ] ; then
            # Untar archive
            TMP_DIR=tmp-$ID
            mkdir -p $TMP_DIR
            tar xjC $TMP_DIR -f $DOWNLOAD

            # Extract the protein file
            mv $TMP_DIR/*.prots.out  $PROTEIN

            # Clean up the archive data directory
            rm -rf $TMP_DIR
            
            # Save to input file
            echo "$PROTEIN,$SPECIES,Protein" >> input_sources_1kp.csv
        fi
    done

This will download the available files to the current working directory and it will create an input file for Orthoflow called ``input_sources_1kp.csv``. 
The first few lines of the file should look like this:

.. code-block:: csv

    file,taxon_string,data_type
    file,taxon_string,data_type
    proteins/AALA.prots.fasta,Meliosma_cuneifolia,Protein
    proteins/ABCD.prots.fasta,Racomitrium_elongatum,Protein
    proteins/ABEH.prots.fasta,Heliotropium_greggii,Protein
    proteins/ABSS.prots.fasta,Sassafras_albidum,Protein
    proteins/ACWS.prots.fasta,Agathis_macrophylla,Protein
    proteins/AEPI.prots.fasta,Linum_leonii,Protein
    proteins/AFLV.prots.fasta,Xerophyllum_asphodeloides,Protein

We are using the protein sequences for the transcriptomes, so we set the ``data_type`` column to ``Protein``.

You can now run Orthoflow with this input file.

Config
======

Now, let's set up the configuration file for Orthoflow. We only need to set the parameters which are different from the default values.

.. code-block:: yaml

    input_sources: "input_sources_1kp.csv" # Alternatively this can be specified on the command line with --files input_sources_1kp.csv
    infer_tree_with_cds_seqs: False # We are using protein sequences
    supermatrix: False  # We will only infer a tree using the supertree (ASTRAL) method

Save this file to ``config_1kp.yaml``.


Running Orthoflow
=================

Phylogenomic analysis of this dataset can then be run with the command:

.. code-block:: bash

    orthoflow --configfile config_1kp.yaml


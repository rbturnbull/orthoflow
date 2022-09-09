# Workflow development guidelines

## Diagram

Link to original on [diagrams.net](https://app.diagrams.net/#G1feeWJLnqI-_EN4x8zY2V9GChWosKFZg3)


![](../_static/orthoflow-workflow-diagram.svg)


## User input

Brain dump of what we need for the user to provide other than a directory with data files. Definitely incomplete so please add your thoughts.
- flow control
    - use SC-OG only, SNAP-OG only, or both combined
    - type of ortholog detection, with checks for adequate input (i.e. reference database for fishing)
    - run trees from AA or NT, I suggest not allowing both for the same run as that also affects other settings (e.g. model types)
    - whole series of alignment filtering options
- program settings
    - IQtree: model (with option to carry out model selection): could use IQtree model definition syntax
    - IQtree: type of branch support




## Data intake module

Must work from input CSV file to determine which type of input the different input files represent. It produces two files for each taxon, one with CDS and one with protein sequences (translated from CDS based on genetic code).

The default name for the input CSV file is `input_sources.csv`. To override that, either edit the `config.yml` file or use pass an argument to the CLI overriding the config setting, e.g. `--config input_sources='/path/to/desired/input/file.csv'` (see [here](https://snakemake.readthedocs.io/en/stable/executing/cli.html) for more details).

1.  Intake of exome data
    
    - this comes in fasta format
    - add taxon\_string field from input CSV with the `add_taxon_to_seqID.py` in `ext_scripts`, keep this output
    - translate sequences using `biokit translate` ([github](https://github.com/JLSteenwyk/BioKIT)), specifying the genetic code given in the input CSV, keep output
2.  Intake of annotated genbank files
    
    - this comes in genbank flatfile format
    - extract CDS features from genbank file with `gbseqextractor` ([github](https://github.com/linzhi2013/gbseqextractor))
    - this essentially converts the input into the exome data from point 1, so downstream processing is identical to 1 from above
    - add taxon\_string field from `input\_sources.csv`, keep this output
    - translate sequences using `biokit translate`, specifying genetic code given in input CSV, keep output
2b.  Index CDSs

    - create samtools faidx indexed copy of all CDS combined (using files with taxon string added but before translation)
    - first all the right fasta files need to be concatenated: `cat *.fa > all_CDS.fa`
    - next this needs to be fed into samtools for indexing: `samtools faidx --fai-idx all_CDS.fai all_CDS.fa`
    - note: it may be possible to pipe the cat output directly into the samtools command and save a step (and a potentially huge intermediate file that no-one would need for other purposes)

## Ortholog module, de novo stream

Uses the translated sequences from the data intake module, clusters them into orthogroups (gene clusters) based on pairwise similarity, then filters these down to the single copy orthogroups (SC-OG) and SNAP orthogroups (SNAP-OG). This module also includes a filtering step for occupancy, i.e. how many taxa are present in the inferred orthogroup.

3.  Orthology inference
    
    - based on the translated CDSs, run an orthology inference program
    - at this stage, I would like two algorithms to be implemented here, OrthoFinder and OrthoMCL
    - this step is where I'd like to implement some extra alternatives later for comparative analysis
    - the output differs between programs, but for orthofinder, among the many outputs are the orthogroup sequences (fasta files) and phylogenetic trees (one per orthogroup)
    - There are too many OGs that are not phylogenetically informative (too few sequences in them – for nuclear genes many are singletons). I wrote a script `filter_OrthoFinder.py` that runs through the output directory of an OrthoFinder run and copies the OGs with more than a user-defined number of sequences to a new directory to reduce the burden of downstream processing. Ideally the minimum number of sequences is set to the occupancy threshold defined by the user.
    - haven't used OrthoMCL recently, so I'm not sure about the outputs it produces, so let's put a placeholder in the workflow but implement this later

4.  Filtering SC-OG
    
    - from the output of step 3, filter out the single copy orthogroups
    - I wrote the `filter_SCOG.pl` script to do this. If the data input into this script are prepared with `filter_OrthoFinder.py` then it already meets the occupancy threshold given by the user.

5.  Inferring and SNAP-OG
    
    - make this step optional, as not all users will want to use this
    - run the OGs that are not SC-OGs through OrthoSNAP
    - use the occupancy threshold given by the user
    - Note: At the moment SNAP-OG works from the trees inferred in OrthoFinder. Ideally we'd implement our own tree inference including support values as that allows OrthoSNAP to take phylogenetic uncertainty into account.

6.  Post-orthogroup organisation
    
    - produce clean output for subsequent module
    - retain only taxon string in sequence ID
    - only protein sequences are used in ortholog module, but also need corresponding CDS
    - use filenames that indicate they are SC or SNAP
    - retain output files, important intermediary output

## Alignment module

Uses the cleaned-up OG files from 7, where we have corresponding CDS and protein files. I denoted these NT (for CDS) and AA (amino acid, i.e. protein). In this module, the aim is to align the sequences and do quality filtering.

7.  Alignment
    
    - first align the protein (amino acid) file with MAFFT
    - Then back-translate the alignment to codons based on the CDS sequences, yielding a correspond alignment of nucleotide sequences.  
    - I wrote a snakemake rule for the MAFFT step: mafft_aa.
    - This will need to be updated to point to the right input and output directories

8.  Filtering
    
    - To be considered an optional step.
    - We talked about this during our 8 April meeting. Steps to be specified in further detail.
    
8b. Wrapping up alignment module

    - Aligned (amino acid) sequences need to be translated back to the original CDS. Two steps need to be taken to achieve this. First, the original CDSs need to be located. I wrote a prototype script (matching_CDSs.py) that does this. This needs to be updated to point to the right input files. The second step is to create a codon-based alignment of the CDSs that matches the AA alignment. Phykit implements this, with the thread_dna function.
    - At the end, the sequence IDs need to be trimmed down to contain just the taxon identifier and produce clean output for the next stages. I wrote "ext_scripts/seqID_taxon_only.pl" to do this and added a rule for this. We probably want this running in a conda environment to be safe but I haven't done that. 
    - Retain output files of both AA and NT, important intermediary output

## Gene tree module

This is an important module that serves multiple purposes. One is to produce the final gene trees, but the module will probably also need to be plugged in to produce intermediary trees as part of the orthologs module, so we need to build this with flexibility in mind. The user will need to specify whether they want trees to be inferred from NT or AA data, and this flexibility needs to be programmed into this somehow. Not sure if this flexibility sits within the module itself, as that may limit the utility of this module for other purposes.

Steps TBD

## Reconciliation module

TBD

## Supermatrix module

11. PhyKIT

    - a file needs to be produced listing all alignment files that need to be concatenated, say this is called files.txt -- I wrote a rule for this but doubt this meets proper workflow development standards
    - Heroen created a conda environment for PhyKIT (envs/phykit.yaml)
    - Heroen wrote a concatenation rule that uses Phykit to create the supermatrix.

12. IQtree phylogenetic inference

    - Heroen added an iqtree environment and wrote a simple iqtree command that will do the job for now
    - Will need updating to include user-specified parameters (at minimum: specification of model or model selection and bootstrapping params) once we know 


## Reporting module

This isn't illustrated on the workflow, but we need to provide a clean report to the user with final results, intermediate outputs, program settings etc.

I feel very strongly that this also includes a list of all the papers users should cite for appropriate acknowledgement of the software that is being used under the hood. This will differ depending on the run, but should be easy to manage.



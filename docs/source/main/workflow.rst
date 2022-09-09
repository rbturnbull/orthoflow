========
Workflow
========

The workflow starts with a data intake module that converts the input data to a uniform data format. 

There are two options to infer orthologs from this, the OrthoFinder stream performing de novo ortholog inference and the OrthoFisher stream using HMM profiles to extract orthologs.

The orthologs then get passed into the alignment module where they are aligned based on their amino acid sequences.

Two paths exist for phylogenetic inference. The supermatrix module uses a concatenated alignment of all orthologs to infer a tree. The gene tree + supertree path infers trees for all orthologs separately and infers a species tree from them (Astral).


.. image:: ../_static/images/orthoflow-workflow-diagram.svg



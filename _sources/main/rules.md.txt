
# Rules

This is an automatically generated list of all supported rules, their docstrings, and command. At the start of each 
workflow run a list is printed of which rules will be run. And while the workflow is running it prints which rules are
being started and finished. This page is here to give an explanation to the user about what each rule does, and for
developers to find what is, and isn't yet supported. Not all Metaphor rules are listed here, only the ones with a
`shell` directive. Rules with `script` or `wrapper` directives are not included. To see all rules in Metaphor, 
please refer to the [workflow source code](https://github.com/vinisalazar/metaphor/tree/main/workflow).
## intake.smk
**gbseqextractor**

Extracts CDS features from GenBank files with gbseqextractor.

Not used if input files already at in fasta format.
gbseqextractor is found here: https://github.com/linzhi2013/gbseqextractor

```
if [ "{params.is_genbank}" = "True" ] ; then
    echo Using gbseqextractor to convert {input.file} to {output}
    gbseqextractor -f {input.file} -types CDS -prefix results/fasta/{wildcards.source}
else
    echo File {input.file} not of type GenBank, creating softlink at {output}
    ln -svr {input.file} {output}
fi
```

**add_taxon**

Prepends the taxon name to the description of each sequence in a fasta file.

**translate**

Translates coding sequences to amino acid sequences using BioKIT.

It relies on the `translation_table` column in `input_sources.csv`.
It expects a number there which corresponds with the NCBI genetic codes: 
https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes

BioKIT is found here: https://github.com/JLSteenwyk/BioKIT

## orthologs.smk
**orthofinder**

Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.

**filter_orthofinder**

Copy out OGs with more than a minimum number of sequences.

:config: filter_orthofinder


% Notes
% -----

% No conda env necesary as the python script only uses the stdlib.

## alignment.smk
**mafft_aa**

Mafft AA

**trim_seqIDs_to_taxon**

Trim sequence IDs to taxon.

## supermatrix.smk
**list_alignments**

List alignments.

```
Concatenate alignments.
```

**concatenate_alignments**

Concatenate alignments.

**iqtree_supermatrix**

IQTREE supermatrix.


---

**Disclaimer**

This page was generated with a script adapted from the 
[seq2science repository](https://github.com/vanheeringen-lab/seq2science).

MIT License

Copyright (c) 2019 Maarten-vd-Sande (vanheeringen-lab)

For the full license, please see the
[script source code](https://github.com/rbturnbull/phyloflow/blob/master/docs/scripts/rule_description.py).

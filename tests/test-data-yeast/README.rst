==================
Yeast Test Example
==================

This is a small version of the Yeast example found in the paper and in the documentation (https://rbturnbull.github.io/orthoflow/main/reproduction_tutorial.html)

It includes a handful of genes from these files:

- ambrosiozyma_kashinagacola.max.pep
- ambrosiozyma_monospora.max.pep
- ascoidea_asiatica.max.pep
- ascoidea_rubescens.max.pep
- candida_auris.max.pep

To run, use this command:

    orthoflow --files yeast5.csv --config infer_tree_with_cds_seqs=False

Original data from here:

    Shen, Xing-Xing (2018). Tempo and mode of genome evolution in the budding yeast subphylum. figshare. Dataset. https://doi.org/10.6084/m9.figshare.5854692.v1


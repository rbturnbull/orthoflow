def test_mafft(run_workflow):
    w = run_workflow("results/alignment/OG0000001.alignment.fa")
    w.assert_contains(">Derbesia_sp_WEST4838|0|KX808497.1|orf422")
    w.assert_contains("MHQTKIVDYLYFFKW--IL")


def test_concat_nuc(run_workflow):
    w = run_workflow("results/alignment/OG0000001.seqs.cds.fa")
    w.assert_contains(">Derbesia_sp_WEST4838|0|KX808497.1|orf422")
    w.assert_contains("ATGCACCAAACTAAGATAGTTGACTATCTCTATTTTTTTAAA")


def test_thread_dna(run_workflow):
    w = run_workflow("results/alignment/OG0000001.alignment.cds.fa")
    w.assert_contains("ATGCACCAAACTAAGATAGTTGACTATCTCTATTTTTTTAAATGG------")


def test_taxon_only(run_workflow):
    w = run_workflow("results/alignment/OG0000001.alignment.taxon_only.cds.fa")
    w.assert_contains(">Derbesia_sp_WEST4838\n")

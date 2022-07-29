def test_mafft(run_workflow):
    w = run_workflow("results/alignment/aligned_proteins/OG0000048.alignment.fa")
    w.assert_contains(">Derbesia_sp_WEST4838|0|KX808497.1|psbM")
    w.assert_contains("MEVNILGLIATALFIIIPTSFLLILYVKTASQNS---------")


def test_get_cds_seq(run_workflow):
    w = run_workflow("results/alignment/seqs_cds/OG0000048.seqs.cds.fa")
    w.assert_contains(">Derbesia_sp_WEST4838|0|KX808497.1|psbM")
    w.assert_contains("ATGGAAGTTAATATTTTAGGATTAATTGCTACTGCTCTATTTATTATTATTCCCA")


def test_thread_dna(run_workflow):
    w = run_workflow("results/alignment/threaded_cds/OG0000048.alignment.cds.fa")
    w.assert_contains(">Derbesia_sp_WEST4838\n")
    w.assert_contains("TGATTTTATATGTTAAAACTGCAAGTCAAAATTCA----")


def test_trim_alignments(run_workflow):
    w = run_workflow("results/alignment/threaded_cds/OG0000048.alignment.cds.fa")
    w.assert_contains(">Derbesia_sp_WEST4838\n")
    w.assert_contains("TGATTTTATATGTTAAAACTGCAAGTCAAAATTCA----")


def test_taxon_only(run_workflow):
    w = run_workflow("results/alignment/taxon_only/OG0000048.alignment.taxon_only.protein.fa")
    w.assert_contains(">Derbesia_sp_WEST4838\n")

from .common import assert_expected

def test_mafft():
    assert_expected("results/alignment/OG0000000.alignment.fa")

def test_concat_nuc():
    assert_expected(f"results/alignment/OG0000000.seqs.cds.fa")

def test_thread_dna():
    assert_expected(f"results/alignment/OG0000000.alignment.cds.fa")

def test_remove_taxon():
    assert_expected(f"results/alignment/OG0000000.alignment.no_taxon.cds.fa")


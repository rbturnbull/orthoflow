from .common import assert_expected

def test_add_taxon():
    assert_expected("results/taxon-added/KX808497.cds.fasta")
    assert_expected("results/taxon-added/MH591080.cds.fasta")


def test_translate():
    assert_expected("results/translated/KX808497.cds.fasta")


def test_extract_cds():
    assert_expected("results/fasta/MH591079.cds.fasta")


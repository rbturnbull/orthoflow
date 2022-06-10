
from .common import assert_expected

def test_alignment_summary():
    assert_expected("results/supermatrix/alignment_summary.txt")


def test_concatenate_alignments():
    assert_expected("results/supermatrix/supermatrix.fa")


# def test_iqtree():
#     assert_expected("results/supermatrix/supermatrix.fa.treefile")


def test_ascii_tree():
    assert_expected("results/supermatrix/ascii_tree.txt")



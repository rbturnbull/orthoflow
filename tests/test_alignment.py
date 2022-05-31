from .common import assert_expected

def test_mafft():
    assert_expected("results/alignment/alignment.fa")


# def test_matched_cds():
#     for i in range(38):
#         assert_expected(f"results/matched_cds/OG{i:07d}.cds.fa")

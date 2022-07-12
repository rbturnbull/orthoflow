def test_alignment_summary(run_workflow):
    run_workflow("results/supermatrix/alignment_summary.txt").assert_expected()


def test_concatenate_alignments(run_workflow):
    run_workflow("results/supermatrix/supermatrix.fa").assert_expected()


# def test_iqtree():
#     assert_expected("results/supermatrix/supermatrix.fa.treefile")


# def test_ascii_tree():
#     assert_expected("results/supermatrix/ascii_tree.txt")

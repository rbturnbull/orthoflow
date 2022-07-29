def test_alignment_summary(run_workflow):
    w = run_workflow("results/supermatrix/alignment_summary.txt")
    w.assert_re(r"\d+\s+Number of taxa")
    w.assert_re(r"\d+\s+Alignment length")
    w.assert_re(r"T\s+\d+")


def test_concatenate_alignments(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.fa")
    w.assert_contains(">Avrainvillea_mazei_HV02664\n")
    w.assert_contains("ATGTCTGGCCTTACAGGAGAGCGACCATTTACTGATATTT")


def test_iqtree(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.fa.treefile")
    w.assert_re(r"Avrainvillea_mazei_HV02664:0\.")
    w.assert_re(r"Bryopsis_plumosa_WEST4718:0\.")
    

def test_supermatrix_ascii(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_ascii.txt")
    w.assert_contains("________ Bryopsis_plumosa_WEST4718")
    w.assert_contains("_____ Derbesia_sp_WEST4838")


def test_supermatrix_render(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_render.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


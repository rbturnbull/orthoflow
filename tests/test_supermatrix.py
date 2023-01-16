def test_alignment_summary_protein(run_workflow):
    w = run_workflow("results/supermatrix/alignment_summary.protein.txt")
    w.assert_re(r"\d+\s+Number of taxa")
    w.assert_re(r"\d+\s+Alignment length")
    w.assert_re(r"T\s+\d+")


def test_alignment_summary_cds(run_workflow):
    w = run_workflow("results/supermatrix/alignment_summary.cds.txt", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_re(r"\d+\s+Number of taxa")
    w.assert_re(r"\d+\s+Alignment length")
    w.assert_re(r"T\s+\d+")


def test_concatenate_alignments_protein(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.protein.fa")
    w.assert_contains(">Avrainvillea_mazei_HV02664\n")
    w.assert_contains("------MKIFEKLIYIVLILLIINL")


def test_concatenate_alignments_cds(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.cds.fa", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(">Avrainvillea_mazei_HV02664\n")
    w.assert_contains("------------------ATGAAAATTTTTGAAAAACTCATTT")


def test_iqtree_protein(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.protein.fa.treefile")
    w.assert_re(r"Avrainvillea_mazei_HV02664:0\.")
    w.assert_re(r"Bryopsis_plumosa_WEST4718:0\.")
    

def test_iqtree_cds(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix.cds.fa.treefile", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_re(r"Avrainvillea_mazei_HV02664:0\.")
    w.assert_re(r"Bryopsis_plumosa_WEST4718:0\.")
    

def test_supermatrix_ascii_protein(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_tree_ascii.protein.txt")
    w.assert_contains("_____ Avrainvillea_mazei_HV02664")
    w.assert_contains("______ Bryopsis_plumosa_WEST4718")


def test_supermatrix_ascii_cds(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_tree_ascii.cds.txt", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("_____ Avrainvillea_mazei_HV02664")
    w.assert_contains("______ Bryopsis_plumosa_WEST4718")


def test_supermatrix_render_protein(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_tree_render.protein.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_supermatrix_render_cds(run_workflow):
    w = run_workflow("results/supermatrix/supermatrix_tree_render.cds.svg", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


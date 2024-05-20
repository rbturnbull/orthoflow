
def test_create_astral_input_protein(run_workflow):
    w = run_workflow("results/supertree/astral_input.protein.trees")
    w.assert_line_count(2)
    w.assert_contains("Caulerpa_cliftonii_HV03798")


def test_create_astral_input_cds(run_workflow):
    w = run_workflow("results/supertree/astral_input.cds.trees", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_line_count(2)
    w.assert_contains("Caulerpa_cliftonii_HV03798")


def test_astral_protein(run_workflow):
    w = run_workflow("results/supertree/supertree.protein.treefile")
    w.assert_contains("Caulerpa_cliftonii_HV03798")

    
def test_astral_cds(run_workflow):
    w = run_workflow("results/supertree/supertree.cds.treefile", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("Caulerpa_cliftonii_HV03798")

    
def test_supertree_ascii_protein(run_workflow):
    w = run_workflow("results/supertree/supertree_ascii.protein.txt")
    w.assert_contains(" Chlorodesmis_fastigiata_HV03865")
    w.assert_contains(" Flabellia_petiolata_HV01202")

    
def test_supertree_ascii_cds(run_workflow):
    w = run_workflow("results/supertree/supertree_ascii.cds.txt", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(" Chlorodesmis_fastigiata_HV03865")
    w.assert_contains(" Flabellia_petiolata_HV01202")


def test_supertree_render_protein(run_workflow):
    w = run_workflow("results/supertree/supertree_render.protein.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_supertree_render(run_workflow):
    w = run_workflow("results/supertree/supertree_render.cds.svg --config infer_tree_with_protein_seqs=0")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')

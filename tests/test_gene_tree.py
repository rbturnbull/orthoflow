

def test_gene_tree_iqtree_protein(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.protein.treefile")
    w.assert_contains("(Caulerpa_cliftonii_HV03798:0.")
    

def test_gene_tree_iqtree_cds(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.cds.treefile", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("(Caulerpa_cliftonii_HV03798:0.")
    

def test_gene_tree_ascii_protein(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002_tree_ascii.protein.txt")
    w.assert_contains("______ Caulerpa_cliftonii_HV03798")
    w.assert_contains("_ Flabellia_petiolata_HV01202")


def test_gene_tree_ascii_cds(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002_tree_ascii.cds.txt", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("______ Caulerpa_cliftonii_HV03798")
    w.assert_contains("_ Flabellia_petiolata_HV01202")


def test_gene_tree_render_protein(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.protein.tree.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_gene_tree_render_cds(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.cds.tree.svg", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_gene_tree_consensus_render_protein(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.protein.consensus-tree.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_gene_tree_consensus_render_cds(run_workflow):
    w = run_workflow("results/gene_tree/OG0000002/OG0000002.cds.consensus-tree.svg", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')


def test_gene_tree_summary_cds(run_workflow):
    w = run_workflow("results/gene_tree/summary/gene_tree_summary.cds.csv")
    w.assert_contains('metric,value,alignment')
    w.assert_exists(expected_files="results/gene_tree/summary/gene_tree_summary.cds.svg")    
    w.assert_contains('<?xml version="1.0" encoding="utf-8" standalone="no"?>', expected_files="results/gene_tree/summary/gene_tree_summary.cds.svg")


def test_gene_tree_summary_protein(run_workflow):
    w = run_workflow("results/gene_tree/summary/gene_tree_summary.protein.csv")
    w.assert_contains('metric,value,alignment')
    w.assert_exists(expected_files="results/gene_tree/summary/gene_tree_summary.protein.svg")    
    w.assert_contains('<?xml version="1.0" encoding="utf-8" standalone="no"?>', expected_files="results/gene_tree/summary/gene_tree_summary.protein.svg")


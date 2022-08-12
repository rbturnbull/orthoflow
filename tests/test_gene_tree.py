def test_gene_tree_iqtree(run_workflow):
    w = run_workflow("results/gene_tree/OG0000003/OG0000003.cds.treefile", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("(Derbesia_sp_WEST4838:")
    

def test_gene_tree_ascii(run_workflow):
    w = run_workflow("results/gene_tree/ascii/OG0000003_tree_ascii.cds.txt", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains("__________ Caulerpa_cliftonii_HV03798")
    w.assert_contains("_____ Flabellia_petiolata_HV01202")

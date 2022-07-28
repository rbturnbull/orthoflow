def test_gene_tree_iqtree(run_workflow):
    w = run_workflow("results/gene_tree/iqtree/OG0000003/")
    w.assert_dir_exists()
    w.assert_glob_count("*.treefile", count=1)
    

def test_gene_tree_ascii(run_workflow):
    w = run_workflow("results/gene_tree/ascii/OG0000003.txt")
    w.assert_contains("__________ Caulerpa_cliftonii_HV03798")
    w.assert_contains("_____ Flabellia_petiolata_HV01202")

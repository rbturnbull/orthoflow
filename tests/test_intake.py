

def test_extract_cds(run_workflow):
    run_workflow("results/intake/MH591079.cds.fa").assert_m()

def test_add_taxon(run_workflow):
    run_workflow(
        ["results/intake/taxon-added/KX808497.cds.fasta", "results/intake/taxon-added/MH591080.cds.fasta"]
    ).assert_expected()

def test_translate(run_workflow):
    run_workflow("results/intake/translated/KX808497.protein.fa").assert_expected()

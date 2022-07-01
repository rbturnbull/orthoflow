def test_add_taxon(run_workflow):
    run_workflow(["results/taxon-added/KX808497.cds.fasta", "results/taxon-added/MH591080.cds.fasta"]).assert_expected()


def test_translate(run_workflow):
    run_workflow("results/translated/KX808497.cds.fasta").assert_expected()


def test_extract_cds(run_workflow):
    run_workflow("results/fasta/MH591079.cds.fasta").assert_expected()

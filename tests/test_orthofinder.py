def test_orthofinder(run_workflow):
    workflow = run_workflow("results/orthofinder/output")
    orthogroup_sequences_dir = (
        workflow.work_dir / "results/orthofinder/output/Orthogroup_Sequences"
    )
    n_sequences = sum(1 for _ in orthogroup_sequences_dir.glob("*.fa"))
    min_seqs = 29
    max_seqs = 31
    assert min_seqs <= n_sequences <= max_seqs
    workflow.assert_contains(">Caulerpa_cliftonii_HV03798|KX808498-truncated.gb", expected_files=orthogroup_sequences_dir / "OG0000000.fa")


def test_orthogroup_classification(run_workflow):
    workflow = run_workflow("results/orthofinder/mcogs.txt")
    workflow.assert_contains("results/orthofinder/output/Orthogroup_Sequences/OG0000000.fa")
    for i in range(1,6):
        workflow.assert_contains(f"results/orthofinder/output/Orthogroup_Sequences/OG000000{i}.fa", expected_files="results/orthofinder/scogs.txt")


def test_orthosnap(run_workflow):
    workflow = run_workflow("results/orthofinder/orthosnap/OG0000000/")
    workflow.assert_contains(">Caulerpa_cliftonii_HV03798|KX808498-truncated.gb|28|psbE\n", expected_files="results/orthofinder/orthosnap/OG0000000/OG0000000_orthosnap_0.fa")
    workflow.assert_contains("MSGTPRERPFSDILTSIRYWVIHSITIPSLFIAGWLF", expected_files="results/orthofinder/orthosnap/OG0000000/OG0000000_orthosnap_0.fa")


def test_orthofinder_report_components(run_workflow):
    workflow = run_workflow("results/orthofinder/report")
    workflow.assert_contains('<div class="table-responsive"><table class="table table-sm table-striped table-hover table-sm align-middle"><', expected_files="results/orthofinder/report/Orthogroups.html")
    workflow.assert_contains('<th class="header" scope="col">Input</th><th class="header" scope="col">', expected_files="results/orthofinder/report/Orthogroups_SpeciesOverlaps.html")
    workflow.assert_contains('Caulerpa_cliftonii_HV03798|KX808498-truncated.gb|3|psaB', expected_files="results/orthofinder/report/Orthogroups_UnassignedGenes.html")

    

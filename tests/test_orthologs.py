def test_orthofinder(run_workflow):
    workflow = run_workflow("results/translated/OrthoFinder/Results_phyloflow")
    orthogroup_sequences_dir = (
        workflow.work_dir / "results/translated/OrthoFinder/Results_phyloflow/Orthogroup_Sequences"
    )
    n_sequences = sum(1 for _ in orthogroup_sequences_dir.glob("*.fa"))
    assert n_sequences == 153, f"Expected 153 orthogroup sequences, found {n_sequences}"
    workflow.assert_expected(orthogroup_sequences_dir / "OG0000000.fa")


def test_filter_orthofinder(run_workflow):
    workflow = run_workflow("results/orthologs")
    orthogroups_dir = workflow.work_dir / workflow.targets[0]
    n_filtered = sum(1 for f in orthogroups_dir.glob("*.fa") if "orthosnap" not in f.name)
    assert n_filtered == 76
    workflow.assert_expected(orthogroups_dir / "OG0000075.fa")


def test_orthosnap(run_workflow):
    workflow = run_workflow("results/orthologs/.OG0000064.orthosnap.flag")
    workflow.assert_expected("results/orthologs/OG0000064.fa.orthosnap.0.fa")
    workflow.assert_expected("results/orthologs/OG0000064.fa.orthosnap.1.fa")
    workflow.assert_expected("results/orthologs/OG0000064.orthosnap.fa")

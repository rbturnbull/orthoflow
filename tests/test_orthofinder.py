def test_orthofinder(run_workflow):
    workflow = run_workflow("results/orthofinder/output")
    orthogroup_sequences_dir = (
        workflow.work_dir / "results/orthofinder/output/Orthogroup_Sequences"
    )
    n_sequences = sum(1 for _ in orthogroup_sequences_dir.glob("*.fa"))
    assert n_sequences == 153, f"Expected 153 orthogroup sequences, found {n_sequences}"
    workflow.assert_md5sum("b2fa93748cc0533f6139fab93787c282", expected_files=orthogroup_sequences_dir / "OG0000000.fa")


def test_generate_orthosnap_input(run_workflow):
    workflow = run_workflow("results/orthofinder/orthosnap_input")
    orthogroups_dir = workflow.work_dir / workflow.targets[0]
    n_filtered = sum(1 for f in orthogroups_dir.glob("*.fa") if "orthosnap" not in f.name)
    assert n_filtered == 4
    workflow.assert_md5sum("37f95650287346ac84e7704cd1833f14", expected_files=orthogroups_dir / "OG0000049.fa")


def test_orthosnap(run_workflow):
    workflow = run_workflow("results/orthofinder/orthosnap/OG0000049/")
    workflow.assert_md5sum("c3fdb4803c07847048773cd1ef8e08a7", expected_files="results/orthofinder/orthosnap/OG0000049/OG0000049.fa.orthosnap.0.fa")

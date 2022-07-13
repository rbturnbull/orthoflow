def test_orthofinder(run_workflow):
    workflow = run_workflow("results/orthofinder/output")
    orthogroup_sequences_dir = (
        workflow.work_dir / "results/orthofinder/output/Orthogroup_Sequences"
    )
    n_sequences = sum(1 for _ in orthogroup_sequences_dir.glob("*.fa"))
    assert n_sequences == 153, f"Expected 153 orthogroup sequences, found {n_sequences}"
    workflow.assert_md5sum("b2fa93748cc0533f6139fab93787c282", expected_files=orthogroup_sequences_dir / "OG0000000.fa")


def test_min_seq_filter_orthofinder(run_workflow):
    workflow = run_workflow("results/orthofinder/min-seq-filtered")
    orthogroups_dir = workflow.work_dir / workflow.targets[0]
    n_filtered = sum(1 for f in orthogroups_dir.glob("*.fa") if "orthosnap" not in f.name)
    assert n_filtered == 76
    workflow.assert_md5sum("1114db6a2aae004f47176a4ab00c6c48", expected_files=orthogroups_dir / "OG0000075.fa")


def test_orthosnap(run_workflow):
    workflow = run_workflow("results/orthofinder/orthosnap/OG0000064.fa")
    workflow.assert_md5sum("7e91c9d6c734664fc685da373218e21b")
def test_orthofinder(run_workflow):
    workflow = run_workflow("results/orthofinder/output")
    orthogroup_sequences_dir = (
        workflow.work_dir / "results/orthofinder/output/Orthogroup_Sequences"
    )
    n_sequences = sum(1 for _ in orthogroup_sequences_dir.glob("*.fa"))
    assert n_sequences == 86, f"Expected 86 orthogroup sequences, found {n_sequences}"
    workflow.assert_md5sum("932322266c4a9649de5da3f6171e9ffa", expected_files=orthogroup_sequences_dir / "OG0000000.fa")


def test_orthogroup_classification(run_workflow):
    workflow = run_workflow("results/orthofinder/mcogs.txt")
    workflow.assert_contains("results/orthofinder/output/Orthogroup_Sequences/OG0000000.fa")
    for i in range(1,6):
        workflow.assert_contains(f"results/orthofinder/output/Orthogroup_Sequences/OG000000{i}.fa", expected_files="results/orthofinder/scogs.txt")


def test_orthosnap(run_workflow):
    workflow = run_workflow("results/orthofinder/orthosnap/OG0000000/")
    workflow.assert_contains(">Caulerpa_cliftonii_HV03798|0|KX808498-truncated.gb|28|psbE\n", expected_files="results/orthofinder/orthosnap/OG0000000/OG0000000_orthosnap_0.fa")
    workflow.assert_contains("MSGTPRERPFSDILTSIRYWVIHSITIPSLFIAGWLF", expected_files="results/orthofinder/orthosnap/OG0000000/OG0000000_orthosnap_0.fa")

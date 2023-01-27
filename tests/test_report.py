

def test_report_protein(run_workflow):
    w = run_workflow("results/report.protein.html")
    w.assert_contains('id="orthofinder-tab"')
    w.assert_contains('id="alignment-tab"')
    w.assert_contains('id="supermatrix-tab"')
    w.assert_contains('id="genetree-tab"')
    w.assert_contains('id="supertree-tab"')
    w.assert_contains('id="bibliography-tab"')


def test_report_cds(run_workflow):
    w = run_workflow("results/report.cds.html", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains('id="orthofinder-tab"')
    w.assert_contains('id="alignment-tab"')
    w.assert_contains('id="supermatrix-tab"')
    w.assert_contains('id="genetree-tab"')
    w.assert_contains('id="supertree-tab"')
    w.assert_contains('id="bibliography-tab"')

    
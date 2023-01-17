

def test_report(run_workflow):
    w = run_workflow("results/report.html")
    w.assert_contains('id="orthofinder-tab"')
    w.assert_contains('id="alignment-tab"')
    w.assert_contains('id="supermatrix-tab"')
    w.assert_contains('id="genetree-tab"')
    w.assert_contains('id="supertree-tab"')
    w.assert_contains('id="bibliography-tab"')

    
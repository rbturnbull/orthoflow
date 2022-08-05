

def test_astral(run_workflow):
    w = run_workflow("results/supertree/supertree.cds.tre")
    w.assert_contains("Derbesia_sp_WEST4838")

    
def test_supertree_ascii(run_workflow):
    w = run_workflow("results/supertree/supertree_ascii.cds.txt")
    w.assert_contains("| Dichotomosiphon_tube")
    w.assert_contains("| Flabellia_peti")


def test_supertree_render(run_workflow):
    w = run_workflow("results/supertree/supertree_render.cds.svg")
    w.assert_contains('<svg class="toyplot-canvas-Canvas"')

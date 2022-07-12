
def test_extract_cds(run_workflow):
    w = run_workflow("results/intake/MH591079.cds.fa")
    w.assert_contains(">MH591079.1|cysT")
    w.assert_contains(">MH591079.1|rpoC2")

def test_add_taxon_KX808497(run_workflow):
    w = run_workflow("results/intake/taxon-added/KX808497.cds.fasta")
    w.assert_contains(">Derbesia_sp_WEST4838|0|KX808497.1|orf153")

def test_add_taxon_MH591080(run_workflow):
    w = run_workflow("results/intake/taxon-added/MH591080.cds.fasta")
    w.assert_contains(">Dichotomosiphon_tuberosus_HV03781|0|MH591080.1|psbA")

def test_translate(run_workflow):
    w = run_workflow("results/intake/translated/KX808497.protein.fa")
    w.assert_contains("LNIILKVFIVNQKCDLYIKYLVLCTYFKDITCIQLPSKVKPKKPIIVELSMLETLDDSFG")

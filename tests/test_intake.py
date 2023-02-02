
def test_extract_cds(run_workflow):
    w = run_workflow("results/intake/MH591083-truncated.cds.fa")
    w.assert_contains(">MH591083-truncated.gb|0|petG")
    w.assert_contains(">MH591083-truncated.gb|1|psaI")


def test_add_taxon_MH591083(run_workflow):
    w = run_workflow("results/intake/taxon-added/MH591083-truncated.cds.fasta")
    w.assert_contains(">Flabellia_petiolata_HV01202|0|MH591083-truncated.gb|0|petG")


def test_add_taxon_KY819064(run_workflow):
    w = run_workflow("results/intake/taxon-added/KY819064-truncated-cds.cds.fasta")
    w.assert_contains(">Chlorodesmis_fastigiata_HV03865|0|KY819064-truncated.cds.fasta|0")


def test_translate(run_workflow):
    w = run_workflow("results/intake/translated/NC_026795-truncated.protein.fa")
    w.assert_contains("MSIQISLRQFINKSINTLFLCGIFLYANPQDTFAYPIFAQQNYENPREPNGRLVCANCHL")

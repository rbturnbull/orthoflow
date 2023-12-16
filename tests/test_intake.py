from pathlib import Path

def test_rename_sequences_MH591083(run_workflow):
    w = run_workflow("results/intake/renamed/MH591083-truncated.renamed.fa")
    w.assert_contains(">Flabellia_petiolata_HV01202|MH591083-truncated.gb|0|petG")


def test_rename_sequences_KY819064(run_workflow):
    w = run_workflow("results/intake/renamed/KY819064-truncated-cds.renamed.fa")
    w.assert_contains(">Chlorodesmis_fastigiata_HV03865|KY819064-truncated.cds.fasta|0")


def test_translate(run_workflow):
    w = run_workflow("results/intake/translated/NC_026795-truncated.translated.fa")
    w.assert_contains("MSIQISLRQFINKSINTLFLCGIFLYANPQDTFAYPIFAQQNYENPREPNGRLVCANCHL")


def test_protein(run_workflow):
    expected_dir = Path(__file__).parent/"test-data-yeast"

    w = run_workflow("results/intake/renamed/ascoidea_rubescens-max.renamed.fa", "--files", "yeast5.csv", "--config", "infer_tree_with_cds_seqs=0", expected_dir=expected_dir)
    w.assert_contains(">ascoidea_rubescens-max|ascoidea_rubescens.max.pep|0|genemark-scaffold_4-processed-gene-8.23-mRNA-1_1")
    w.assert_contains("MSFDEQTPVSLLLSPGSIFIGANRQPQCSDYSSTLNIVAFGSQNLVSLFNPLSPDNVGVFKTLKGHKDEVIC")

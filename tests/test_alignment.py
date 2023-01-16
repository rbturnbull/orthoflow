def test_mafft(run_workflow):
    w = run_workflow("results/alignment/aligned_proteins/OG0000000_orthosnap_0.protein.alignment.fa")
    w.assert_contains(">Caulerpa_cliftonii_HV03798|0|KX808498-truncated.gb|28|psbE")
    w.assert_contains("TDRLNALKQINKNL---")


def test_get_cds_seq(run_workflow):
    w = run_workflow("results/alignment/seqs_cds/OG0000001.cds.seqs.fa", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(">Caulerpa_cliftonii_HV03798|0|KX808498-truncated.gb|22|rpl23")
    w.assert_contains("ATGTTTGATTTTTTAAATAAACCATTAATAACAGAAAAAGCAACTCAACTTATTGAA")


def test_thread_dna(run_workflow):
    w = run_workflow("results/alignment/threaded_cds/OG0000048.cds.alignment.fa", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(">Derbesia_sp_WEST4838\n")
    w.assert_contains("TGATTTTATATGTTAAAACTGCAAGTCAAAATTCA----")


def test_trim_alignments(run_workflow):
    w = run_workflow("results/alignment/trimmed/OG0000003.trimmed.cds.alignment.fa", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(">Derbesia_sp_WEST4838\n")
    w.assert_contains("ATGACAGCTATTTTACAACGTCGCGAAAATACGACTTTATGGGC")


def test_taxon_only(run_workflow):
    w = run_workflow("results/alignment/taxon_only/OG0000003.taxon_only.protein.alignment.fa")
    w.assert_contains(">Caulerpa_cliftonii_HV03798\n")
    w.assert_contains(">Avrainvillea_mazei_HV02664\n")
    w.assert_contains(">Chlorodesmis_fastigiata_HV03865\n")


def test_taxon_only_cds(run_workflow):
    w = run_workflow("results/alignment/taxon_only/OG0000003.taxon_only.cds.alignment.fa", "--config", "infer_tree_with_protein_seqs=0")
    w.assert_contains(">Caulerpa_cliftonii_HV03798\n")
    w.assert_contains(">Avrainvillea_mazei_HV02664\n")
    w.assert_contains(">Chlorodesmis_fastigiata_HV03865\n")



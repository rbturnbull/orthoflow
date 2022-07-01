def test_mafft(run_workflow):
    run_workflow("results/alignment/OG0000001.alignment.fa").assert_expected()


def test_concat_nuc(run_workflow):
    run_workflow("results/alignment/OG0000001.seqs.cds.fa").assert_expected()


def test_thread_dna(run_workflow):
    run_workflow("results/alignment/OG0000001.alignment.cds.fa").assert_expected()


def test_remove_taxon(run_workflow):
    run_workflow("results/alignment/OG0000001.alignment.no_taxon.cds.fa").assert_expected()

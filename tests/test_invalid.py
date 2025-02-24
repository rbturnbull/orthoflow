from pathlib import Path
import pytest
from subprocess import CalledProcessError

invalid_expected_dir = Path(__file__).parent/"test-data-invalid"


def test_fasta_alphabet(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--inputs", "fasta_alphabet.fa", expected_dir=invalid_expected_dir )


def test_fasta_invalid(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--inputs", "invalid.fa", "--no-ignore-non-valid-files", expected_dir=invalid_expected_dir )


def test_gbk_invalid(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--inputs", "invalid.gb", "--no-ignore-non-valid-files", expected_dir=invalid_expected_dir )


def test_gbk_alphabet(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--inputs", "alphabet.gb", "--no-ignore-non-valid-files", expected_dir=invalid_expected_dir)


def test_infinite_loop(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "-i", "input_sources_infinite.csv", "--ignore-non-valid-files", expected_dir=invalid_expected_dir)


def test_ignore_faulty_file(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "-i", "input_sources.csv", "--ignore-non-valid-files", expected_dir=invalid_expected_dir)
    w.assert_not_contains("alphabet.gb")


def test_lowercase_ok(run_workflow):
    w = run_workflow("results/intake/renamed/lowercase.renamed.fa --inputs lowercase.fa", expected_dir=invalid_expected_dir)
    w.assert_contains("AGAGAGAGAGAGGAATGC")


def test_protein_lowercase_ok(run_workflow):
    w = run_workflow("results/intake/renamed/protein_intake_truncated_lowercase.renamed.fa", "--inputs", "protein_intake_truncated_lowercase.yml", expected_dir=invalid_expected_dir)
    w.assert_not_contains("mklflifyfltflflpiiiviynvsqnsfdyfleraldpvaictyqtsislsliacifnt")
    w.assert_contains("MKLFLIFYFLTFLFLPIIIVIYNVSQNSFDYFLERALDPVAICTYQTSISLSLIACIFNT")
    w.assert_not_contains("iililvneiieqlkkltlfeaselvkqieqifgvetsnissvpiaiepsidqqietkqdt")
    w.assert_contains("IILILVNEIIEQLKKLTLFEASELVKQIEQIFGVETSNISSVPIAIEPSIDQQIETKQDT")


def test_ignore_empty_seqs_true(run_workflow):
    w = run_workflow("results/intake/renamed/codons.renamed.fa --inputs codons.fa --ignore-empty-seqs", expected_dir=invalid_expected_dir)
    w.assert_not_contains("emptysequence")


def test_ignore_empty_seqs_false(run_workflow):
    with pytest.raises(CalledProcessError):
        w = run_workflow("results/intake/renamed/codons.renamed.fa --inputs codons.fa --no-ignore-empty-seqs", expected_dir=invalid_expected_dir)


def test_protein_input_error(run_workflow):
    with pytest.raises(CalledProcessError):
        w = run_workflow("orthofinder", "--inputs", "input_sources_protein.csv", "--ignore-empty-seqs", expected_dir=invalid_expected_dir)

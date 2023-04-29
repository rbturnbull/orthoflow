from pathlib import Path
import pytest
from subprocess import CalledProcessError

invalid_expected_dir = Path(__file__).parent/"test-data-invalid"

def test_fasta_invalid_codon(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "codons.fa", expected_dir=invalid_expected_dir )

def test_fasta_alphabet(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "fasta_alphabet.fa", expected_dir=invalid_expected_dir )

def test_fasta_invalid(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "invalid.fa", expected_dir=invalid_expected_dir )

def test_gnb_invalid(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "invalid.gb", expected_dir=invalid_expected_dir )

def test_gnb_alphabet(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "alphabet.gb", expected_dir=invalid_expected_dir)

def test_infinite_loop(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "input_sources_infinite.csv", expected_dir=invalid_expected_dir)

def test_ignore_faulty_file(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "--files", "input_sources.csv", "--config", "ignore_non_valid_files=1", expected_dir=invalid_expected_dir)
    with pytest.raises(Exception) as err:
        w.assert_contains("alphabet.gb")

def test_ignore_faulty_sequence(run_workflow):
    w = run_workflow("results/intake/cds/codons.cds.fa", "--files", "input_sources.csv", "--config", "ignore_non_valid_files=1", expected_dir=invalid_expected_dir)
    with pytest.raises(Exception) as err:
        w.assert_contains("emptysequence")

def test_error_no_alignments(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/orthofinder/all/", "--files", "input_sources.csv", "--config", "ignore_non_valid_files=1", "ortholog_min_seqs=20", "ortholog_min_taxa=20", expected_dir=invalid_expected_dir)


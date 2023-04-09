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

def test_ignore_files(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "--files", "alphabet.gb", "--config", "ignore_non_valid_files=1", expected_dir=invalid_expected_dir)
    w.assert_exists(expected_files="logs/warnings/non_valid_objects.txt")
    w.assert_contains("alphabet.gb", expected_files="logs/warnings/non_valid_objects.txt")

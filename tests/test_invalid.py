from pathlib import Path
import pytest
from subprocess import CalledProcessError

invalid_expected_dir = Path(__file__).parent/"test-data-invalid"

def test_fasta_invalid(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "invalid.fa", expected_dir=invalid_expected_dir )


def test_fasta_invalid_codon(run_workflow):
    with pytest.raises(CalledProcessError) as err:
        w = run_workflow("results/intake/input_sources.csv", "--files", "codon.fa", expected_dir=invalid_expected_dir )



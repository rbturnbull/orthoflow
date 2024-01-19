from pathlib import Path
import pytest

warnings_expected_dir = Path(__file__).parent/"test-data-invalid"

def test_warning_ignore_files(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "--files", "alphabet.gb", "--config", "ignore_non_valid_files=1", expected_dir=warnings_expected_dir)
    w.assert_exists(expected_files="logs/warnings/non_valid_objects.txt")
    w.assert_contains(
        "Sequence in file 'alphabet.gb' for taxon 'Caulerpa_cliftonii' is not valid: Invalid pattern found in 'KX808498.1'.\n"
        "Character 'U' at position 2 found which is not in alphabet 'ATCGNatcgn-'. IGNORED", 
        expected_files="logs/warnings/non_valid_objects.txt"
    )


def test_warning_missing_taxa(run_workflow):
    w = run_workflow("logs/warnings/missing_taxa.txt", "--files", "input_sources.csv", "--config", "ignore_non_valid_files=1", expected_dir=warnings_expected_dir)
    w.assert_exists(expected_files="logs/warnings/missing_taxa.txt")
    w.assert_contains("alphabetfasta", expected_files="logs/warnings/missing_taxa.txt")
    w.assert_contains("codonsfasta", expected_files="logs/warnings/missing_taxa.txt")
    w.assert_contains("The following taxon/taxa has/have no orthougroups with current configurations:", expected_files="logs/warnings/missing_taxa.txt")


def test_warning_suffix(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "--config", "ignore_non_valid_files=1", expected_dir=warnings_expected_dir)
    w.assert_exists(expected_files="logs/warnings/warning_suffix.txt")
    w.assert_contains("Suffix from file 'KY819064-truncated.cds.fafafafa' is not Fasta or Genbank. File is assumed to be in Fasta format.", expected_files="logs/warnings/warning_suffix.txt")

def test_warning_trans_table(run_workflow):
    w = run_workflow("results/intake/input_sources.csv", "--config", "ignore_non_valid_files=1", expected_dir=warnings_expected_dir)
    w.assert_exists(expected_files="logs/warnings/missing_translation_table.txt")
    w.assert_contains("Translation table for file fasta_alphabet.fa alphabetfasta is missing", expected_files="logs/warnings/missing_translation_table.txt")

def test_warning_configuration_file(run_workflow):
    w = run_workflow("orthofinder", "-R", "--files", "input_sources.csv", "--config", "ortholog_min_seqs=1", "supertree=0", "supermatrix=0", "ignore_non_valid_files=1", expected_dir=warnings_expected_dir)
    w.assert_exists(expected_files="logs/warnings/configuration_warnings.txt")
    w.assert_contains("The variable ortholog_min_seqs is 1 and should be 3 or larger.", expected_files="logs/warnings/configuration_warnings.txt")
    w.assert_contains("Both the 'supermatrix' and 'supertree' variable are False in the configuration file.", expected_files="logs/warnings/configuration_warnings.txt")

from unittest.mock import patch
from pathlib import Path
from orthoflow.workflow.rules import intake_utils

TEST_DATA_SMALL = Path(__file__).parent/"test-data-small"
TEST_DATA = Path(__file__).parent/"test-data"


def test_input_csv_test_data_small():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA_SMALL/"input_sources.csv")
    assert isinstance(input_dictionary, intake_utils.OrthoflowInputDictionary)
    assert len(input_dictionary) == 7
    assert list(input_dictionary.keys()) == ['KX808498-truncated', 'KY509313-truncated', 'MH591083-truncated', 'MH591084-truncated', 'MH591085-truncated', 'NC_026795-truncated', 'KY819064-cds']
    
    for data in input_dictionary.values():
        data.translation_table == 11
        assert data.file.exists()
        assert data.file.parent == TEST_DATA_SMALL
    

def test_input_csv_test_data():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA/"input_sources.csv")
    assert isinstance(input_dictionary, intake_utils.OrthoflowInputDictionary)
    assert len(input_dictionary) == 12
    assert list(input_dictionary.keys()) == ['KY509313', 'NC_026795', 'KX808498', 'KY819064-cds', 'KX808497', 'MH591079', 'MH591080', 'MH591081', 'MH591083', 'MH591084', 'MH591085', 'MH591086']
    
    for data in input_dictionary.values():
        data.translation_table == 11
        assert data.file.exists()
        assert data.file.parent == TEST_DATA
        

def test_input_csv_genbank():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA_SMALL/"MH591083-truncated.gb")
    assert len(input_dictionary) == 1
    item = input_dictionary["MH591083-truncated"]
    assert item.translation_table == 11
    assert item.taxon_string == "Flabellia_petiolata"
    assert item.file == TEST_DATA_SMALL/"MH591083-truncated.gb"
    assert item.data_type == "GenBank"
    

def test_input_csv_fasta():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA_SMALL/"KY819064.cds.fasta")
    assert len(input_dictionary) == 1
    item = input_dictionary["KY819064-cds"]
    assert item.translation_table == 1
    assert item.taxon_string == "KY819064-cds"
    assert item.file == TEST_DATA_SMALL/"KY819064.cds.fasta"
    assert item.data_type == "Fasta"
    

def test_input_yaml():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA_SMALL/"KY819064.cds.yaml")
    assert len(input_dictionary) == 1
    item = input_dictionary["KY819064-cds"]
    assert item.translation_table == 11
    assert item.taxon_string == "Chlorodesmis_fastigiata_HV03865"
    assert item.file == TEST_DATA_SMALL/"KY819064.cds.fasta"
    assert item.data_type == "Fasta"


def test_input_toml():
    input_dictionary = intake_utils.create_input_dictionary(TEST_DATA_SMALL/"NC_026795-truncated.toml")
    assert len(input_dictionary) == 1
    item = input_dictionary["NC_026795-truncated"]
    assert item.file == TEST_DATA_SMALL/"NC_026795-truncated.txt"
    assert item.data_type == "GenBank"
    assert item.translation_table == 11
    assert item.taxon_string == "Bryopsis_plumosa"


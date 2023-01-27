import pandas as pd
from pathlib import Path
from typing import List, Union, Dict
from dataclasses import dataclass
from Bio import GenBank, SeqIO
import json
import yaml
import toml


@dataclass
class OrthoflowInput():
    file: Path
    taxon_string: str = ""
    translation_table: str = ""
    data_type: str = ""

    def validate(self):
        self.file = Path(self.file)
        if not self.file.exists():
            raise FileNotFoundError(f"Cannot find input file {self.file}")
        
        self.taxon_string = self.taxon_string or self.file.name
        self.data_type = self.data_type or "Fasta"
        self.translation_table = self.translation_table or config.get("default_translation_table", TRANSLATION_TABLE_DEFAULT)

    def stub(self):
        suffix = self.file.suffix
        return self.file.name[:-len(suffix)].replace(".", "-")


class OrthoflowInputDictionary(dict):
    def __init__(self, sources:List[OrthoflowInput]):
        for source in sources:
            source.validate()
            stub = source.stub()

            if stub in self:
                raise ValueError(f"Multiple input sources with same stub '{stub}': {self[stub].file} and {source.file}")

            self[stub] = source


def read_input_source_dictionary(data:Dict, directory:Path=None):
    # Check to see if multiple files are given
    if "files" in data:
        inputs = []
        for i in data["files"]:
            inputs += read_input_source_dictionary(i, directory=directory)
        return inputs

    # If no "files" key is in the dictionary, then this dictionary is for a single file
    if "file" not in data:
        print(f"The 'file' attribute is not given in {data}.")
        raise ValueError()

    file = Path(data["file"])
    
    # Make relative to directory if given
    if directory:
        file = Path(directory, file)

    if not Path(file).exists():
        raise FileNotFoundError(f"File '{file}'' does not exist.")

    input_objects_data = read_input_source(file)
    
    # Override values from dictionary
    for input_object in input_objects_data:
        if "taxon_string" in data:
            input_object.taxon_string = data["taxon_string"]

        if "data_type" in data:
            input_object.data_type = data["data_type"]

        if "translation_table" in data:
            input_object.translation_table = data["translation_table"]

    return input_objects_data


def read_input_source_json(input_source:Path) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    with open(input_source) as json_file:
        data = json.load(json_file)
        return read_input_source_dictionary(data, directory=input_source.parent)
    

def read_input_source_yaml(input_source:Path) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    data = yaml.safe_load(input_source.read_text())
    return read_input_source_dictionary(data, directory=input_source.parent)


def read_input_source_toml(input_source:Path) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    data = toml.loads(input_source.read_text())
    return read_input_source_dictionary(data, directory=input_source.parent)


def read_input_source_pandas(input_csv:Path) -> List[OrthoflowInput]:
    input_csv = Path(input_csv)
    df = pd.read_csv(input_csv)

    input_objects = []
    for _, data in df.iterrows():

        input_objects += read_input_source_dictionary(data, directory=input_csv.parent)
    
    return input_objects


def read_input_source_genbank(file:Path, taxon_string=None, translation_table=None) -> List[OrthoflowInput]:
    # If no taxon_string is given then get it from the organism in the GenBank metadata
    if not taxon_string:
        with open(file) as handle:
            record = GenBank.read(handle)
            taxon_string = record.organism
    
    # Get the translation table from the CDS qualifiers and check that they are all the same
    if not translation_table:
        for seq in SeqIO.parse(file, "genbank"):
            for feature in seq.features:
                if feature.type == "CDS" and "transl_table" in feature.qualifiers:
                    cds_translation_table = feature.qualifiers["transl_table"]
                    if not translation_table:
                        translation_table = cds_translation_table
                    elif translation_table != cds_translation_table:
                        raise ValueError(
                            "Inconsistent translation table values ({translation_table}, {cds_translation_table}) in '{input_source}'"
                        )

    return [OrthoflowInput(file=file, taxon_string=taxon_string, translation_table=translation_table, data_type="GenBank")]
                    

def read_input_source_fasta(file:Path) -> List[OrthoflowInput]:
    return [OrthoflowInput(file=file, data_type="Fasta")]


def read_input_source(input_source:Union[Path, str, List]) -> List[OrthoflowInput]:
    # If this is a list, then run the function on all the items in the list
    if isinstance(input_source, list):
        inputs = []
        for i in input_source:
            inputs += read_input_source(i)
        return inputs

    # If not a list then it must be a kind of path
    input_source = Path(input_source)
    if not input_source.exists():
        raise FileNotFoundError(f"Could not find your input file '{input_source}'.")

    suffix = input_source.suffix.lower()
    if suffix in [".csv", ".tsv"]:
        return read_input_source_pandas(input_source)
    
    if suffix in [".genbank", ".gb", ".gbk"]:
        return read_input_source_genbank(input_source)

    if suffix in [".fasta", ".fa"]:
        return read_input_source_fasta(input_source)

    if suffix == ".json":
        return read_input_source_json(input_source)

    if suffix == ".toml":
        return read_input_source_toml(input_source)

    if suffix in [".yaml", ".yml"]:
        return read_input_source_yaml(input_source)

    return [OrthoflowInput(file=input_source)]


def create_input_dictionary(input_source:Union[Path, str, List]) -> OrthoflowInputDictionary:
    input_list = read_input_source(input_source)
    return OrthoflowInputDictionary(input_list)


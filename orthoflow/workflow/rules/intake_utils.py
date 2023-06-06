import pandas as pd
from pathlib import Path
from typing import List, Union, Dict
from dataclasses import dataclass
from Bio import GenBank, SeqIO
import json
import yaml
from rich.console import Console
console = Console()
import toml
from phytest.bio.sequence import Sequence
from dataclasses import dataclass, field

if "config" not in locals():
    config = {}

if "TRANSLATION_TABLE_DEFAULT" not in locals():
    TRANSLATION_TABLE_DEFAULT = 1


@dataclass
class OrthoflowInput():
    file: Path
    taxon_string: str = ""
    translation_table: str = ""
    data_type: str = ""
    valid_file: bool = True
    faulty_list: list = field(default_factory=list)
    trans_table_default: bool = False
    suffix_unknown: bool = False

    def __eq__(self, other): 
        if not isinstance(other, OrthoflowInput):
            return False

        return all([
            self.file.absolute() == other.file.absolute(),
            self.taxon_string == other.taxon_string,
            self.translation_table == other.translation_table,
            self.is_genbank() == other.is_genbank(),
        ])

    def validate(self):
        self.file = Path(self.file)
        if not self.file.exists():
            self.faulty_list(f"Cannot find input file {self.file}")
            self.valid_file = False
            return
        
        self.data_type = self.data_type or "Fasta"
        self.validate_taxon_string()
        self.validate_translation_table()
        self.validate_sequence()

    def stub(self):
        suffix = self.file.suffix
        return self.file.name[:-len(suffix)].replace(".", "-").replace(" ", "_")

    def is_genbank(self) -> bool:
        return self.data_type.lower() in ["genbank", "gb", "gbk"]        

    def validate_taxon_string(self):
        if not self.taxon_string:
            if self.is_genbank():
                # If no taxon_string is given then get it from the organism in the GenBank metadata
                with open(self.file) as handle:
                    record = GenBank.read(handle)
                    self.taxon_string = record.organism
            else:
                self.taxon_string = self.stub()
        
        self.taxon_string = self.taxon_string.replace(" ", "_")
        
    def validate_translation_table(self):
        # Get the translation table from the CDS qualifiers and check that they are all the same
        if not self.translation_table and self.is_genbank():
            for seq in SeqIO.parse(self.file, "genbank"):
                for feature in seq.features:
                    if feature.type == "CDS" and "transl_table" in feature.qualifiers:
                        cds_translation_table = feature.qualifiers["transl_table"][0]
                        if not self.translation_table:
                            self.translation_table = cds_translation_table
                        elif self.translation_table != cds_translation_table:
                            raise ValueError(
                                f"Inconsistent translation table values ({self.translation_table}, {cds_translation_table}) in '{self.file}'"
                            )

        if not self.translation_table:
            self.translation_table = config.get("default_translation_table", TRANSLATION_TABLE_DEFAULT) 
            self.trans_table_default = True
    

        if not str(self.translation_table).isdigit():
            raise ValueError(f"Translation table {self.translation_table} not numeric")

        self.translation_table = int(self.translation_table)
        if not (1 <= self.translation_table <= 33):
            raise ValueError(
                f"Translation table {self.translation_table} not valid. "
                "See values here: https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes"
            )
        
    def validate_sequence(self):
        if self.is_genbank():
            #check whether file contains valid nucleotides only
            sequences = Sequence.parse(self.file, "genbank")
            for sequence in sequences:
                try:
                    sequence.assert_valid_alphabet()
                    sequence.assert_length(min=1)
                except:
                    self.valid_file = False
                    self.faulty_list.append(f"Sequence in file {self.file} {self.taxon_string} is not valid")

            #check whether file contains annotated genes 
            count = 0
            for seq in SeqIO.parse(self.file, "genbank"):
                for feat in seq.features:
                    if feat.type == "CDS":
                        count += 1
            if count == 0:
                self.valid_file = False
                self.faulty_list.append(f"File {self.file} {self.taxon_string} does not contain any sequences")
        
        if not self.is_genbank():
            sequences = Sequence.parse(self.file, "fasta")
            count = 0
            for sequence in sequences:
                try:
                    if self.data_type == "Protein":
                        sequence.assert_valid_alphabet(alphabet = "ACDEFGHIKLMNPQRSTVWYX*")
                    else:
                        sequence.assert_valid_alphabet()
                    sequence.assert_length(min=1)
                except:
                    self.faulty_list.append(f"Sequence {sequence.id} in file {self.file} {self.taxon_string} is not valid")
                count += 1
            if count == 0:
                self.valid_file = False
                self.faulty_list.append(f"File {self.file} {self.taxon_string} does not contain any sequences")


class OrthoflowInputDictionary(dict):
    def __init__(self, sources:List[OrthoflowInput], ignore_non_valid_files, warnings_dir=None):

        faulty_object_present = False

        # Extra test for warning message if ignore_non_valid_files=True
        extra_text = ""
        if ignore_non_valid_files:
            extra_text = " and is/are ignored"
        
        # Create lists for warning messages per category
        list_of_faulty_lists = []
        list_of_default_trans_tables = []
        list_of_unknown_suffix = []

        for source in sources:
            stub = source.stub()

            if stub in self:
                raise ValueError(f"Multiple input sources with same stub '{stub}': {self[stub].file} and {source.file}")
            
            source.validate()

            # add file to dict if valid
            if source.valid_file:
                self[stub] = source

            # Add warnings for faulty objects
            if source.faulty_list:
                if len(list_of_faulty_lists) == 0:
                    list_of_faulty_lists.append("File(s) and/or sequence(s) not valid" +  extra_text)
                faulty_object_present = True
                list_of_faulty_lists.append("\n".join(source.faulty_list) + extra_text + "\n")

            # Add warning messages for translation tables and suffices. Only when file is valid or files can be ignored.
            if source.valid_file or not ignore_non_valid_files:
                if source.trans_table_default and not source.data_type == 'Protein':
                    if len(list_of_default_trans_tables) == 0:
                        list_of_default_trans_tables.append("Translation table value missing and unable to retrieve from file, default has been used.\n")
                    list_of_default_trans_tables.append(f"Translation table for file {source.file} {source.taxon_string} is missing \nand could not be retrieved from text so default '{source.translation_table}' has been used.")

                if source.suffix_unknown:
                    if len(list_of_unknown_suffix) == 0:
                        list_of_unknown_suffix.append(f"File(s) not Fasta or Genbank file.\n")     
                    list_of_unknown_suffix.append(f"Suffix from file '{source.file}' is not Fasta or Genbank. File is assumed to be in Fasta format.")

        # Write warnings to warning files
        if warnings_dir:
            non_valid_files_warning_file = warnings_dir/"non_valid_objects.txt"
            non_valid_files_warning_file.write_text("\n".join(str(item) for item in list_of_faulty_lists))
            default_trans_table_warning_file = warnings_dir/"missing_translation_table.txt"
            default_trans_table_warning_file.write_text("\n".join(str(item) for item in list_of_default_trans_tables))
            suffix_warning_file = warnings_dir/"warning_suffix.txt"
            suffix_warning_file.write_text("\n".join(str(item) for item in list_of_unknown_suffix))

        if faulty_object_present:
            if not ignore_non_valid_files:
                raise ValueError(f"File(s) and/or sequence(s) not valid, check the warning folder to see the faulty objects")
            

    def write_csv(self, csv):
        with open(csv, "w") as f:
            print("stub", "file", "data_type", "taxon_string", "translation_table", file=f, sep=",")
            for stub, data in self.items():
                print(stub, data.file, data.data_type, data.taxon_string, data.translation_table, file=f, sep=",")


def read_input_source_dictionary(data:Dict, file_list, directory:Path=None):
    # Check to see if multiple files are given
    if "files" in data:
        inputs = []
        for i in data["files"]:
            inputs += read_input_source_dictionary(i, file_list, directory=directory)
        return inputs

    # If no "files" key is in the dictionary, then this dictionary is for a single file
    if "file" not in data:
        raise ValueError(f"The 'file' attribute is not given in {data}.\nPlease check the formatting of your input file.")

    # Open file if name is not empty
    try:
        file = Path(data["file"])
    except:
        raise ValueError(f"File name is empty, please check your input file:\n{data}")
    
    # Make relative to directory if given
    if directory:
        file = Path(directory, file)
    
    if not Path(file).exists():
        raise FileNotFoundError(f"File '{file}' does not exist.")

    input_objects_data = read_input_source(file, file_list)

    # Override values from dictionary
    for input_object in input_objects_data:
        if "taxon_string" in data and not input_object.taxon_string:
            input_object.taxon_string = data["taxon_string"]

        if "data_type" in data and not input_object.data_type:
            input_object.data_type = data["data_type"]

        if "translation_table" in data and not input_object.translation_table:
            input_object.translation_table = data["translation_table"]
            input_object.trans_table_default = False

    return input_objects_data


def read_input_source_json(input_source:Path, file_list) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    with open(input_source) as json_file:
        try:
            data = json.load(json_file)
        except:
            raise ValueError(f"{input_source} is invalid and cannot be read, please check the file.")
        if not data:
            raise ValueError(f"{input_source} is empty, please check the file.")
        return read_input_source_dictionary(data, file_list, directory=input_source.parent)
    

def read_input_source_yaml(input_source:Path, file_list) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    try:
        data = yaml.safe_load(input_source.read_text())
        data != {}
    except:
        raise ValueError(f"{input_source} is invalid and cannot be read, please check the file.")
    if not data:
        raise ValueError(f"{input_source} is empty, please check the file.")
    return read_input_source_dictionary(data, file_list, directory=input_source.parent)


def read_input_source_toml(input_source:Path, file_list) -> List[OrthoflowInput]:
    input_source = Path(input_source)
    try:
        data = toml.loads(input_source.read_text())
    except:
        raise ValueError(f"{input_source} is invalid and cannot be read, please check the file.")
    if not data:
        raise ValueError(f"{input_source} is empty, please check the file.")
    return read_input_source_dictionary(data, file_list, directory=input_source.parent)


def read_input_source_pandas(input_csv:Path, file_list) -> List[OrthoflowInput]:
    input_csv = Path(input_csv)

    # Open and read CSV file. Fill missing variables with '0' and make sure translation table values are integers, as a missing
    # value will turn them into floats.
    try: 
        df = pd.read_csv(input_csv)
        df.fillna(0, inplace=True)
        df.translation_table = df.translation_table.astype(int)
    except:
        raise IOError(f"File '{input_csv} is empty or not valid, please check the file and its formatting.")
    
    if not "file" in df:
        raise ValueError(f"File '{input_csv}' does not contain the right attribute")

    input_objects = []
    for _, data in df.iterrows():

        input_objects += read_input_source_dictionary(data, file_list, directory=input_csv.parent)

    
    return input_objects


def read_input_source(input_source:Union[Path, str, List], file_list) -> List[OrthoflowInput]:
    # Check for infinite loops due to self reference
    if str(input_source) in file_list:
        raise AssertionError(f"File {input_source} refers to itself and the program has been ended to prevent an infinite loop. Please check the file.")
    file_list.append(str(input_source))

    # If files are comma separated then split them
    if isinstance(input_source, str) and "," in input_source:
        input_source = input_source.split(",")

    # If this is a list, then run the function on all the items in the list
    if isinstance(input_source, list):
        inputs = []
        for i in input_source:
            inputs += read_input_source(i, file_list)
        return inputs

    # If not a list then it must be a kind of path
    input_source = Path(input_source)
    if not input_source.exists():
        raise FileNotFoundError(f"Could not find your input file '{input_source}'.")
  
    suffix = input_source.suffix.lower()
    if suffix in [".csv", ".tsv"]:
        return read_input_source_pandas(input_source, file_list)
    
    if suffix in [".genbank", ".gb", ".gbk"]:
        return [OrthoflowInput(file=input_source, data_type="GenBank")]

    if suffix in [".fasta", ".fa"]:
        return [OrthoflowInput(file=input_source)]#, data_type="Fasta"

    if suffix == ".json":
        return read_input_source_json(input_source, file_list)

    if suffix == ".toml":
        return read_input_source_toml(input_source, file_list)

    if suffix in [".yaml", ".yml"]:
        return read_input_source_yaml(input_source, file_list)
    
    return [OrthoflowInput(file=input_source, suffix_unknown=True)]

def create_input_dictionary(input_source:Union[Path, str, List], ignore_non_valid_files, warnings_dir=None) -> OrthoflowInputDictionary:
    if len(str(input_source)) == 0:
        raise FileNotFoundError("No input source given, please check the config file.")
    input_list = read_input_source(input_source, [])
    return OrthoflowInputDictionary(input_list, ignore_non_valid_files, warnings_dir)
  

#!/usr/bin/env python3
from pathlib import Path
from Bio import AlignIO
import typer
import pickle
import linecache


class MultiFastaIndex():
    def __init__(self, files):
        self.files = list(files)
        self.id_refs = {}

        for file_index, file in enumerate(self.files):
            with open(file) as f:
                for line_number, line in enumerate(f):
                    if line.startswith(">"):
                        seq_id = line[1:].strip()

                        if seq_id in self.id_refs:
                            print(f"duplicate seq_id {seq_id}")
                            continue

                        self.id_refs[seq_id] = (file_index, line_number+2)
                    
    def save(self, path):
        with open(path, 'wb') as f:
            pickle.dump(self, f)

    @classmethod
    def load(cls, path):
        with open(path, 'rb') as f:
            return pickle.load(f)

    def __len__(self):
        return len(self.id_refs)

    def __getitem__(self, seq_id):
        file_index, line_number = self.id_refs[seq_id]
        filename = str(self.files[file_index])
        return linecache.getline(filename, line_number).strip()

    def __contains__(self, seq_id):
        return seq_id in self.id_refs


def get_cds_seq(
    cds_dir: Path = typer.Option(..., help="The directory of the input CDS files that have the taxon_string prepended to seqIDs."),
    alignment: Path = typer.Option(..., help="The path to the alignment file to get the correct order."),
    output_file: Path = typer.Option(..., help="The file for the concatenated sequences."),
):
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """

    # HACK This should be done once per directory and saved
    multifastaindex = MultiFastaIndex(cds_dir.glob("*.cds.fa"))

    with open(output_file, 'w') as f:
        alignment = AlignIO.read(alignment, "fasta")
        
        for row in alignment:
            if row.id not in multifastaindex:
                raise Exception(f"cannot find {row.id} in multifastaindex")
            f.write(f">{row.id}\n{multifastaindex[row.id]}\n")
        





if __name__ == "__main__":
    typer.run(get_cds_seq)

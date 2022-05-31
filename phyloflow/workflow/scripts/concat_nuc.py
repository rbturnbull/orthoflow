from pathlib import Path
from Bio import SeqIO, AlignIO

import typer


def concat_nuc(
    cds_dir: Path = typer.Option(..., help="The directory of the input CDS files that have the taxon_string prepended to seqIDs."),
    alignment: Path = typer.Option(..., help="The path to the alignment file to get the correct order."),
    output_file: Path = typer.Option(..., help="The file for the concatenated sequences."),
):
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    cds_files = list(cds_dir.glob("*.cds.fasta"))
    cds_dict = {}
    for cds_file in cds_files: 
        for seq in SeqIO.parse(cds_file,"fasta"):
            print(seq.id)
            if seq.id in cds_dict:
                print(f"Duplicate seq id {seq.id}")
                continue
            cds_dict[seq.id] = seq.seq

    with open(output_file, 'w') as f:
        alignment = AlignIO.read(alignment, "fasta")
        for row in alignment:
            assert row.id in cds_dict
            f.write(f">{row.id}\n{cds_dict[row.id]}\n")


if __name__ == "__main__":
    typer.run(concat_nuc)

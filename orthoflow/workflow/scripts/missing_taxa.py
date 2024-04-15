#!/usr/bin/env python3
from pathlib import Path
import csv
import typer


def get_taxa_in_fasta(fasta_files):
    taxa = set()
    for path in fasta_files:
        with open(path) as file:
            for line in file:
                if line.startswith(">"):
                    taxa.add(line[1:].strip())
    return taxa


def print_missing_in_alignments(ortholog_taxa, alignments_list:Path, description:str):
    if not alignments_list or not alignments_list.is_file():
        return

    alignments = alignments_list.read_text().strip().split("\n")
    taxa_in_alignments = get_taxa_in_fasta(alignments)
    missing = ortholog_taxa - taxa_in_alignments
    if missing:
        text = f"{len(missing)} taxa are" if len(missing) > 1 else "1 taxon is"
        print(f"{text} missing in {description}:")
        for taxon in missing:
            print(f"\t{taxon}")


def missing_taxa(
    input_csv:Path,
    orthologs_path:Path,
    alignments_list_protein:Path,
    alignments_list_cds:Path,
):
    # Get the required list of taxa in the input
    expected_taxa = set()
    with open(input_csv) as file:
        reader = csv.DictReader(file)
        for row in reader:
            expected_taxa.add(row['taxon_string'])

    # Look for list of taxa in OGs
    ortholog_taxa = get_taxa_in_fasta(orthologs_path.glob("*.fa"))
    missing = expected_taxa - ortholog_taxa
    if missing:
        text = f"{len(missing)} taxa are" if len(missing) > 1 else "1 taxon is"
        print(f"{text} missing in all orthogroups with the current Orthoflow configuration:")
        for taxon in missing:
            print(f"\t{taxon}")
    else:
        print("All taxa are found in orthogroups.")
        
    print_missing_in_alignments(ortholog_taxa, alignments_list_protein, "protein alignment after filtering")
    print_missing_in_alignments(ortholog_taxa, alignments_list_cds, "CDS alignment after filtering")


if __name__ == "__main__":
    typer.run(missing_taxa)

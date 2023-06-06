import os

def check_configurations(input_dictionary, WARNINGS_DIR, ORTHOLOG_MIN_SEQS_DEFAULT, config ):
    configuration_warnings = []

    # check whether configurations are present and not faulty
    config_dict = {"orthofinder_use_scogs" : bool, "orthofinder_use_snap_ogs" : bool, "ortholog_min_seqs" : int, "ortholog_min_taxa" : int, "minimum_trimmed_alignment_length_cds" : int, "minimum_trimmed_alignment_length_proteins" : int, "max_trimmed_proportion" : float, "use_orthofisher" : bool, "supermatrix" : bool, "supertree" : bool, "ignore_non_valid_files" : bool, "infer_tree_with_protein_seqs" : bool, "infer_tree_with_cds_seqs" : bool, "amino_acid_input" : bool}
    for key in config_dict.keys():
        if not isinstance(config.get(key),config_dict[key]) and config.get(key) not in [0,1]:
            configuration_warnings.append(f"'{key}' configuration is missing from configuration file or faulty, so default has been assumed.")

    # warn for odd or inconsistent config variables
    if config["amino_acid_input"] and config["infer_tree_with_cds_seqs"]:
        configuration_warnings.append("Both protein_input and infer_tree_with_cds_seqs are True in the configuration file")
        raise ValueError("Both protein_input and infer_tree_with_cds_seqs are True in the configuration file.\nIt is not possible to make a tree with cds if there is protein amino acid input present.\nPlease change the infer_tree_with_cds_seqs variable to False or remove amino acid input and set amino_acid_input to False.")
    
    if not config["supermatrix"] and not config["supertree"]:
        configuration_warnings.append("Both the 'supermatrix' and 'supertree' variable are False in the configuration file. No tree will be made.")

    if not config["infer_tree_with_protein_seqs"] and not config["infer_tree_with_cds_seqs"]:
        configuration_warnings.append("Both the 'infer_tree_with_protein_seqs' and 'infer_tree_with_cds_seqs' variable are False in the configuration file.\nDefault inference method protein sequence is used.")

    min_seqs = config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)
    if min_seqs < 3:
        configuration_warnings.append(f"The variable ortholog_min_seqs is {min_seqs} and should be 3 or larger. It has been automatically set to 3.")

    # raise error when amino acid sequence present in input and infer_tree_with_protein_seqs is TRUE
    if config["infer_tree_with_cds_seqs"]:
        for key, value in input_dictionary.items():
            if value.data_type == 'Protein':
                raise ValueError("Amino acid input found while configuration variable infer_tree_with_cds_seqs is True.\nPlease change infer_tree_with_cds_seqs to False or remove the amino acid / protein files from the analysis.")

    # check hmm files in configuration file
    if config["use_orthofisher"] == True:
        for file in config["orthofisher_hmmer_files"]:
            if not os.path.isfile(file):
                configuration_warnings.append(f"hmm file {file} does not exist and is not used as an hmm profile.")

    # write the found warnings to the warning file
    if len(configuration_warnings) > 0:
        configuration_warnings.insert(0, "Configuration file has raised warnings due to uncommon configurations.\n")
    config_warning_file = WARNINGS_DIR/"configuration_warnings.txt"
    config_warning_file.write_text("\n".join(str(item) for item in configuration_warnings))

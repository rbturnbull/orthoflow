def all_translated(wildcards):
    all_translated = 
    with open(query_output, "r") as fp:
        names = fp.readline().strip().split(" ")
    return names


rule orthofinder:
  """
  Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.
  """

  input:
      sequences = lambda wildcards: checkpoints.translate.get(**wildcards).output,
      directory = directory("translated")
  output:
      temp(directory("translated/OrthoFinder"))
  conda:
      ENV_DIR / "orthofinder.yaml"
  shell:
      "orthofinder -d -f {input.directory}"


rule filter_orthofinder:
  """
  Copy out OGs with more than a minimum number of sequences.

  :config: filter_orthofinder

  Notes
  -----
  
  No conda env necesary as the python script only uses the stdlib.
  """

  input:
      rules.orthofinder.output
  output:
      directory("results/orthologs")
  params:
      min_seq = config[rules.name]['min_sequences']
  shell:
      "python ext_scripts/filter_OrthoFinder.py -i {input} -o {output} -m {params.min_seq}"

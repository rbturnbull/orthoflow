import sys
from pathlib import Path
from snakemake import main as snakemake_main

def run():
    argv = sys.argv
    snakefile_path = Path(__file__).parent/"workflow/Snakefile"
    argv.extend([
        "--snakefile", 
        str(snakefile_path),
    ])

    snakemake_main()

if __name__ == "__main__":
    run()

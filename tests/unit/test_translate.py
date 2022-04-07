import os
import sys

import subprocess as sp
from tempfile import TemporaryDirectory
import shutil
from pathlib import Path, PurePosixPath

sys.path.insert(0, os.path.dirname(__file__))

import common


def test_translate():

    with TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        tests_dir = Path(__file__).parent
        data_path = tests_dir/"translate/data"
        expected_path = tests_dir/"translate/expected"
        conda_dir = tests_dir/".tests-conda"

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir)

        # dbg
        print("results/translated/MH591079.cds.fasta", file=sys.stderr)

        # Run the test job.
        sp.check_output([
            "python",
            "-m",
            "snakemake", 
            "results/translated/MH591079.cds.fasta",
            "-f", 
            "-j1",
            "--keep-target-files",
            "--conda-frontend",
            "conda",
            "--use-conda",
            "--conda-prefix",
            conda_dir,
            "--directory",
            workdir,
        ])

        # Check the output byte by byte using cmp.
        # To modify this behavior, you can inherit from common.OutputChecker in here
        # and overwrite the method `compare_files(generated_file, expected_file), 
        # also see common.py.
        common.OutputChecker(data_path, expected_path, workdir).check()

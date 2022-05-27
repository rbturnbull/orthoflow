import os
import sys

import subprocess as sp
from tempfile import TemporaryDirectory
import shutil
from pathlib import Path, PurePosixPath

sys.path.insert(0, os.path.dirname(__file__))

import common


def test_gbseqextractor():

    with TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        tests_dir = Path(__file__).parent
        data_path = tests_dir / "test-data/data/"
        results_path = workdir / "results/fasta"
        expected_path = tests_dir / "test-data/results/fasta"
        conda_dir = tests_dir / ".tests-conda"

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir)

        # Target rule to run until
        until = "add_taxon"

        # dbg
        print("results/fasta/MH591079.cds.fasta", file=sys.stderr)

        # Run the test job.
        sp.check_output(
            [
                "phyloflow",
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
                "--until",
                until,
            ]
        )

        # Check the output byte by byte using cmp.
        # To modify this behavior, you can inherit from common.OutputChecker in here
        # and overwrite the method `compare_files(generated_file, expected_file),
        # also see common.py.
        common.OutputChecker(data_path, expected_path, results_path).check()

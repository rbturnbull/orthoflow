from pathlib import Path
import subprocess as sp
from tempfile import TemporaryDirectory
import shutil
import difflib
import typer
import filecmp


class FilesDiffer(Exception):
    pass


def assert_expected(expected_files):
    if isinstance(expected_files, (str, Path)):
        expected_files = [expected_files]

    with TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        tests_dir = Path(__file__).parent
        data_path = tests_dir / "test-data/"
        conda_dir = tests_dir / ".tests-conda"

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir)

        # Remove expected files to ensure they are generated
        for expected_file in expected_files:
            working_dir_path = workdir/expected_file
            working_dir_path.unlink()

        # Run the test job.
        sp.check_output(
            [
                "phyloflow",
                expected_files[0],
                "-f",
                "-j1",
                "--directory",
                workdir,
                "--keep-target-files",
                "--use-conda",
                "--conda-frontend",
                "conda",
                "--conda-prefix",
                conda_dir,
            ]
        )

        # Check expected files
        for expected_file in expected_files:
            generated_path = workdir/expected_file
            expected_path = data_path/expected_file

            if filecmp.cmp(generated_path, expected_path, shallow=False):
                continue

            with open(generated_path) as generated, open(expected_path) as expected:
                generated_lines = generated.readlines()
                expected_lines = expected.readlines()

                diff = difflib.unified_diff(generated_lines, expected_lines)
                
                if diff:
                    for line in diff:
                        if line.startswith('+'):
                            fg = typer.colors.GREEN
                        elif line.startswith('-'):
                            fg = typer.colors.RED
                        elif line.startswith('^'):
                            fg = typer.colors.BLUE
                        else:
                            fg = None

                        typer.secho(line.rstrip(), fg=fg)

                    raise FilesDiffer(f"'{expected_file}' does not match expected (see diff).")

import re
import difflib
import hashlib
import shutil
import subprocess as sp
from pathlib import Path
from typing import List, NewType, Optional, Union

import pytest
import typer

TargetsType = NewType("TargetsType", Union[str, Path, List[Union[str, Path]]])


class FilesDiffer(Exception):
    pass


class SnakemakePytestException(Exception):
    pass


def _md5sum(filename):
    md5 = hashlib.md5()
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(128 * md5.block_size), b''):
            md5.update(chunk)
    return md5.hexdigest()


def _targets_to_pathlist(pathlist: TargetsType) -> List[Path]:
    if isinstance(pathlist, (Path, str)):
        pathlist = [pathlist]
    for ii, path in enumerate(pathlist):
        if isinstance(path, str):
            pathlist[ii] = Path(path)
    return pathlist


class Workflow:
    def __init__(self, targets: List[Path], work_dir: Path, expected_dir: Path):
        self.targets = targets
        self.work_dir = work_dir
        self.expected_dir = expected_dir

    def get_expected_paths(self, expected_files: Optional[TargetsType] = None) -> List[Path]:
        if expected_files is None:
            return self.targets
        
        return _targets_to_pathlist(expected_files)

    def assert_md5sum(self, checksums:Union[str, List[str]], *, expected_files: Optional[TargetsType] = None,):
        if isinstance(checksums, str):
            checksums = [checksums]

        for expected_file, checksum in zip(self.get_expected_paths(expected_files), checksums):
            generated_path = self.work_dir / expected_file
            generated_checksum = _md5sum(generated_path)
            if generated_checksum != checksum:
                raise SnakemakePytestException(
                    f"The md5 checksum for '{generated_path}' is '{generated_checksum}'."
                    f"This differs from the expected checksum '{checksum}'."
                )

    def assert_contains(self, strings:Union[str, List[str]], *, expected_files: Optional[TargetsType] = None,):
        if isinstance(strings, str):
            strings = [strings]
        
        for expected_file in self.get_expected_paths(expected_files):
            generated_path = self.work_dir / expected_file
            text = generated_path.read_text()
            for expected_string in strings:
                if expected_string not in text:
                    raise SnakemakePytestException(
                        f"The file '{generated_path}' does not contain the string '{expected_string}':\n" + 
                        text
                    )

    def assert_re(self, patterns:Union[str, List[str]], expected_files: Optional[TargetsType] = None,):
        if isinstance(patterns, str):
            patterns = [patterns]
        
        for expected_file in self.get_expected_paths(expected_files):
            generated_path = self.work_dir / expected_file
            text = generated_path.read_text()
            for pattern in patterns:
                if not re.search(pattern, text):
                    raise SnakemakePytestException(
                        f"The file '{generated_path}' does match with pattern '{pattern}':\n" + 
                        text
                    )

    def assert_exists(self, expected_files: Optional[TargetsType] = None, diff_on_fail: bool = True) -> bool:
        for expected_file in self.get_expected_paths(expected_files):
            generated_path = self.work_dir / expected_file
            assert generated_path.exists()

    def assert_dir_exists(self, expected_files: Optional[TargetsType] = None, diff_on_fail: bool = True) -> bool:
        for expected_file in self.get_expected_paths(expected_files):
            generated_path = self.work_dir / expected_file
            assert generated_path.exists()
            assert generated_path.is_dir()

    def assert_expected(self, expected_files: Optional[TargetsType] = None, diff_on_fail: bool = True) -> bool:
        # Check expected files
        for expected_file in self.get_expected_paths(expected_files):
            generated_path = self.work_dir / expected_file
            expected_path = self.expected_dir / expected_file

            if _md5sum(generated_path) == _md5sum(expected_path):
                continue

            # If different then write the diff
            if diff_on_fail:
                with open(generated_path) as generated, open(expected_path) as expected:

                    generated_lines = generated.readlines()
                    expected_lines = expected.readlines()

                    diff = difflib.unified_diff(generated_lines, expected_lines, n=0)

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

                raise FilesDiffer(f"'{expected_file}' does not match expected.")

        return True


@pytest.fixture
def run_workflow(tmpdir: Path):
    def _run_workflow(targets: TargetsType) -> Workflow:
        targets = _targets_to_pathlist(targets)

        work_dir = Path(tmpdir) / "work_dir"
        tests_dir = Path(__file__).parent.resolve()
        expected_dir = tests_dir / "test-data"
        conda_dir = expected_dir/".snakemake/conda/"

        shutil.copytree(
            expected_dir,
            work_dir,
            ignore=shutil.ignore_patterns('.snakemake'),
        )

        sp.check_output(
            [
                "phyloflow",
                *targets,
                "-f",
                "-j1",
                "--directory",
                work_dir,
                "--keep-target-files",
                "--conda-prefix",
                conda_dir,
            ]
        )

        return Workflow(targets, work_dir, expected_dir)

    return _run_workflow

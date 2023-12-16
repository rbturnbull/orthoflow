import tempfile
from pathlib import Path
from orthoflow.workflow.scripts.filter_alignments import filter_alignments
from typer.testing import CliRunner

TEST_DATA_SMALL = Path(__file__).parent/"test-data-small"

def test_filter_alignments_test_data_small_cds():
    trimmed_dir = TEST_DATA_SMALL/"results/alignment/trimmed_cds"
    untrimmed_dir = TEST_DATA_SMALL/"results/alignment/threaded_cds"

    trimmed = sorted(trimmed_dir.glob("*.cds.alignment.fa"))
    untrimmed = sorted(untrimmed_dir.glob("*.cds.alignment.fa"))

    output = filter_alignments(trimmed, untrimmed, min_length=110, max_trimmed_proportion=0.5, n_jobs=-1)
    expected_names = [
        'OG0000000.trimmed.cds.alignment.fa', 
        'OG0000001.trimmed.cds.alignment.fa', 
        'OG0000004.trimmed.cds.alignment.fa', 
        'OG0000005_orthosnap_0.trimmed.cds.alignment.fa', 
        'OG0000006.trimmed.cds.alignment.fa',
    ]
    assert [x.name for x in output] == expected_names

    with tempfile.TemporaryDirectory() as tmpdir:
        output_txt = Path(tmpdir)/"alignments.txt"
        output = filter_alignments(trimmed, untrimmed, min_length=110, max_trimmed_proportion=0.99, n_jobs=-1, output_txt=output_txt)
        expected_names = ['OG0000000.trimmed.cds.alignment.fa', 'OG0000004.trimmed.cds.alignment.fa']
        assert [x.name for x in output] == expected_names

        assert output_txt.exists()
        output_lines = output_txt.read_text().strip().split("\n")
        assert len(output_lines) == len(expected_names)
        assert output_lines[0].endswith(expected_names[0])

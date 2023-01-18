


def test_summarize_information_content(run_workflow):
    w = run_workflow("results/summary/information_content.csv")
    w.assert_contains('metric,value,alignment')
    w.assert_exists(expected_files="results/summary/information_content.svg")    
    w.assert_contains('<?xml version="1.0" encoding="utf-8" standalone="no"?>', expected_files="results/summary/information_content.svg")


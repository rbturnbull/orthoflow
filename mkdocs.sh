(cd docs && poetry run sphinx-build -b html -E source _build/html)
echo docs/_build/html/index.html

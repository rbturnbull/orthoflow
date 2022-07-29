for i in $(ls tests/test-data/results/orthologs/scog/)
do
  nseq=$(grep ">" tests/test-data/results/orthologs/scog/$i | wc -l)
  min_seq=$(echo "5")
  if [[ $nseq -ge $min_seq ]]
  then
    echo "true"
  else
    continue
  fi
done
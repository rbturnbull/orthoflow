from Bio import SeqIO
for seq in SeqIO.parse("KX808497.gb", "genbank"):
    for feat in seq.features:
        if feat.type == "CDS":
            feat_seq = feat.extract(seq)
            print(">",seq.id,"|",feat.qualifiers["gene"][0],"\n",feat_seq.seq,sep="")
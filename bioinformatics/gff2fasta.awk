#!/usr/bin/gawk -f

#### gff2fasta.awk
##
## Description:
## Given a GFF file with embedded sequence data,
## output a FASTA file of the DNA regions (genes) described in the GFF rows.

function revComp (seq,
                  rev_comp_seq,seq_bases,i) {

    comp["A"] = "T"
    comp["T"] = "A"
    comp["G"] = "C"
    comp["C"] = "G"

    split(seq,seq_bases,"")
    for(i==length(seq); i>=1; i--)
	rev_comp_seq = rev_comp_seq revComp(seq_bases[i])

    return rev_comp_seq

}

BEGIN { FS = OFS = "\t" }

NF == 9 {
    
    feature = ($3 "_" ++feature_type_counter[$3])
    features[feature]
    feature_seq[feature] = $1
    feature_start[feature] = $4
    feature_end[feature] = $5
    feature_score[feature] = $6
    feature_strand[feature] = $7
    feature_desc[feature] = $9
    next
}

/>/ { 
    split($0,parts,">")
    seq_name = parts[2] 
    next
}

{ seqs[seq_name] = seqs[seq_name] $0 }

END { 
    for(feature in features) {

	temp_subseq = substr(seqs[feature_seq[feature]],
			     feature_start[feature],
			     feature_end[feature]-feature_start[feature]+1)

	if(feature_strand[feature] == "+" )
	    feature_subseq = temp_subseq
	else
	    feature_subseq = revComp(temp_subseq)

	print ">" feature "|" feature_seq " " feature_start[feature] "|" feature_end[feature] "|" feature_score[feature] "|" feature_strand[feature] "|" feature-desc[feature]
	print feature_subseq

    }

}
	
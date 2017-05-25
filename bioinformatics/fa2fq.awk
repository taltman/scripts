#!/usr/bin/gawk -f

#### fa2fq.awk: Convert a FASTA file into FASTQ format

function printEntry(defline,seq) {

    print defline
    print seq
    print "+"
    gsub(/./,"I",seq)
    print seq
    
}

/^>/ && seq !="" {
    printEntry(defline,seq)
    seq = ""
}

/^>/ { gsub(/^>/, "@"); defline=$0; next}

{ seq = seq $0 }

END { printEntry(defline, seq) }



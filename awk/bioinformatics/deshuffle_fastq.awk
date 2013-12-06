#!/usr/bin/gawk -f

### deshuffle_fastq.awk
##
## Copyright Tomer Altman
##
### Description:
##
## Given a FASTQ file representing paired-end reads in an interleaved
## fashion (i.e., entry n+1 stores the first read in the pair, and entry
## n+2 stores the second read in the pair), split the ends into separate
## FASTQ files. 
##
## This utility script is necessary because some software provides
## paired-end read data in an interleaved fashion, while others expect the
## read ends to be in separate files.

BEGIN {entry=1} 

## Switching entry values:

FNR != 1 && (FNR%4) == 1 {
    if  ( entry == 1 )
	entry = 2
    else
	entry = 1
}

## Printing entries to corresponding files:

entry == 1 {
    print $0 >> "deshuffled_reads1.fq"
}

entry == 2 { 
    print $0 >> "deshuffled_reads2.fq"
}

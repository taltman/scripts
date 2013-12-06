#!/usr/bin/gawk -f

### fq2tbl.awk
##
## Copyright Tomer Altman
##
### Description
##
## Given a FASTQ-formatted file, transform it such that instead of having
## four separate lines per record, all lines are turned into tab-delimited
## fields on a single line per record. This makes it more convenient for
## scripting.

BEGIN{ 
    OFS="\t"
    count=0 }

{ line[(FNR%4)] = $0 }

(FNR%4) == 0 {

    split(line[1],id_fields)
    fastq_id = substr(id_fields[1],2)

    print ++count, fastq_id, line[1], line[2], line[3], line[0]

}
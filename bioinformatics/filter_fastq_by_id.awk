#!/usr/bin/gawk -f

### filter_fastq_by_id.awk
##
### Copyright Tomer Altman 
##
### Description:
##
## Given a list of read IDs to remove, 
## take a FASTQ file and remove entries that have matching read IDs.
## This is useful for filtering out reads, such as human reads from
## microbiome samples.
##
## -v filter_dir=in means the read IDs are for reads to keep
## -v filter_dir=out means the read IDs are for reads to remove


BEGIN { if( filter_dir == "") filter_dir = "in" }

## Hash up read identifiers:
NR == FNR { read_ids[$0]++ ; next }


## Print out the SAM mapped read identifiers:
## Only for the second file, which is the SAM input,
## and only if the read ID is in the read_ids hash:


## Set entry to true if not in read ID hash:
(FNR%4) == 1 { matched_entry_p = substr($1,2) in read_ids }

## If true, print the line:
(filter_dir == "in" && matched_entry_p) || (filter_dir == "out" && !matched_entry_p)

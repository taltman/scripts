#!/usr/bin/gawk -f

### filter_fasta_by_id.awk
##
### Copyright Tomer Altman 
##
### Description:
##
## Given a list of read IDs to remove, 
## take a FASTA file and remove entries that have matching defline IDs.
## This is useful for filtering out reads, such as human reads from
## microbiome samples.
##
## -v filter_dir=in means the defline IDs are for sequences to keep
## -v filter_dir=out means the defline IDs are for sequences to remove
##
## This script has a bug if the read id file is zero bytes. Nothing gets
## printed out, even for filter_dir=out.


BEGIN { if( filter_dir == "") filter_dir = "in" }

## Hash up read identifiers:

## Realized that NR==FNR idiom is buggy when passed a zero-byte file:
ARGIND == 1 { defline_ids[$0]++ ; next }


## Set entry to true if not in read ID hash:
/^>/ { matched_entry_p = substr($1,2) in defline_ids }


## If true, print the line:
(filter_dir == "in" && matched_entry_p) || (filter_dir == "out" && !matched_entry_p)

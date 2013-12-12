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

## Hash up Human read identifiers:
ARGIND == 1 { 
    human_reads[$0]++
    next
}

## Print out the SAM mapped read identifiers:
## Only for the second file, which is the SAM input,
## and only if it is not a header line, and only
## if we don't already have that read:

## Set entry to true if not in human read ID hash:
(FNR%4) == 1 && ! (substr($1,2) in human_reads)  { entry=1 }

## If true, print the line:
entry == 1 { print }

## Before we evaluate the next FASTQ entry, reset entry to zero:
(FNR%4) == 0 { entry=0 }

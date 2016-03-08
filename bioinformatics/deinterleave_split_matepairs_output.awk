#!/usr/bin/gawk -f

## The output of the split_matepairs script in the seq_crumbs project has
## paired-end and unpaired reads commingled in the same FASTQ file. This
## program splits it out into three files
## reads_1.fastq
## reads_2.fastq
## unpaired_reads.fastq

(NR%4)==1 && /^@.*\\1/ { outfile = "read_1.fastq" }
(NR%4)==1 && /^@.*\\2/ { outfile = "read_2.fastq" }
(NR%4)==1 && /^@/ && ! /\\1/ && ! /\\2/ { outfile = "unpaired_read.fastq" }

{ print > outfile }
   

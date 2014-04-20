#!/usr/bin/gawk -f

## join.awk
##
## Description:
##
## Like venerable 'join', but no sorting of keys necessary.
##
##
 
BEGIN { FS=OFS="\t" }

NR == FNR {

    first_file[$b]

}

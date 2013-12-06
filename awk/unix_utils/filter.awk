#!/usr/bin/gawk -f

## Based on list of IDs, filter second file

FNR == NR { ids[$1]; next }

{
    
    gsub(/>/,"",$1)
    if ( $1 in ids ) print
    
}
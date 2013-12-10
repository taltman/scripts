#!/usr/bin/gawk -f

## Based on list of IDs, filter second file
## Options:
## Use '-v key1=NUM1' and/or '-v ke2=NUM2', where NUM1 and NUM2 are column numbers (1-indexed), 
## to indicate which columns should be used to serve as keys.
## I guess this makes this kind of like paste (which is on my hit-list)

BEGIN { 
    key1= key1?key1:1 
    key2= key2?key2:1 
}

FNR == NR { ids[$key1]; next }

$key2 in ids
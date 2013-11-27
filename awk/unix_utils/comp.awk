#!/usr/bin/gawk -f

### comp.awk
##
## AWK implementation of comp, that doesn't require sorted inputs.
##
## TODO:
##
## * Implement this using runawk. 
## * Test this implementation using mawk vs. gawk
## * Test this implementation using Perl vs. sort & comm
## * Print weights in adjoining columns, or as "::NNN" suffix to entry

BEGIN { FS=OFS="\t" }

## This line is the only pattern matching the first file entries:
FNR == NR { file1_lines[$0]++; next }

## For the first occurrence of the shared line in the second file, print the entry keep track of the intersection size & weight:
$0 in file1_lines && ! ($0 in shared_lines) { 

    shared_lines[$0]
    intersection_size++
    intersection_weight += file1_lines[$0]    
    print $0, "", ""

}

## Increment shared line counts:
$0 in file1_lines { intersection_weight++; next }

## These get executed for non-shared lines in file2:
! ( $0 in file1_lines ) && ! ( $0 in file2_lines ) { 
    file2_setdiff_size++ 
    print "", "", $0
}

{ file2_lines[$0]++; file2_setdiff_weight++}

END {

    ## Loop over first file entries:
    for ( file1_line in file1_lines )
	if ( ! (file1_line in shared_lines) ) {
	    print "", file1_line, ""
	    file1_setdiff_count++
	    file1_setdiff_weight += file1_lines[file1_line]
	}

	print "Unweighted Jaccard Coefficient: ", intersection_size / (intersection_size + file1_setdiff_count + file2_setdiff_count ) > "/dev/stderr"
	print "Weighted Jaccard Coefficient: ", intersection_weight / (intersection_weight + file1_setdiff_weight + file2_setdiff_weight ) > "/dev/stderr"
}


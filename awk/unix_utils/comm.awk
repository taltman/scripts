#!/usr/bin/gawk -f

### comm.awk
##
## Copyright held by Tomer Altman
##
## AWK implementation of comm, that doesn't require sorted inputs.
## Thus, unlike venerable comm, there's no need to perform a sort on input files.
## This means that this script has linear time and memory complexity,
## whereas the equivalent pipeline using sort and comm will have
## quadratic or log-linear time complexity (unclear what the memory
## complexity would be, as I believe sort will fail-over to doing
## merge sort on the file system if memory is exhausted).
##
##
##
## TODO:
##
## * Implement this using runawk. 
## * Print weights in adjoining columns, or as "::NNN" suffix to entry
## * Make stats collection optional (to improve memory profile)
##   In this case, memory consumption will be proportional to size of
##   first file
## * Warn when smallest file (in terms of hashing) is not the first
##   file
##   ... and make such warnings optional
## * Make implementation more memory efficient, deleting array members
##   when necessary
##   Currently it is buffering memory proportional to the size of the two
##   input files and the intersection combined! It should ideally scale as a function of
##   the union of the two files...
## * Code might be simpler if we use just a single multidimensional array

## * Allow user to specify column ranges for keys
## * Become feature-complete with GNU comm
## * Test this implementation using mawk vs. gawk
## * Test this implementation using Perl vs. sort & comm
##   (use /usr/bin/time and valgrind)
## * Stat to add: # distinct lines for each file

BEGIN { FS=OFS="\t" }

## This line is the only pattern matching the first file entries:
FNR == NR { file1_size++; file1_lines[$0]++; next }

## For the first occurrence of the shared line in the second file, print the entry keep track of the intersection size & weight:
$0 in file1_lines && ! ($0 in shared_lines) { 

    shared_lines[$0]
    intersection_size++
    intersection_weight += file1_lines[$0]    
    print "", "", $0

}

## Increment shared line counts:
$0 in file1_lines { intersection_weight++; next }

## These get executed for non-shared lines in file2:
! ( $0 in file1_lines ) && ! ( $0 in file2_lines ) { 
    file2_setdiff_size++ 
    print "", $0, ""
}

{ file2_lines[$0]; file2_setdiff_weight++}

END {

    file2_size = FNR

    ## Loop over first file entries:
    for ( file1_line in file1_lines )
	if ( ! (file1_line in shared_lines) ) {
	    print file1_line, "", ""
	    file1_setdiff_size++
	    file1_setdiff_weight += file1_lines[file1_line]
	}

    print "File 1 number of lines:", file1_size > "/dev/stderr"
    print "File 2 number of lines:", file2_size > "/dev/stderr"
    print "File 1 unique lines:", intersection_size + file1_setdiff_size > "/dev/stderr"
    print "File 2 unique lines:", intersection_size + file2_setdiff_size > "/dev/stderr"
    print "Common lines:", intersection_weight > "/dev/stderr"
    print "Distinct common lines:", intersection_size > "/dev/stderr"
    print "Fraction of shared distinct lines over all distinct lines for file 1:", intersection_size / (intersection_size + file1_setdiff_size) > "/dev/stderr"
    print "Fraction of shared distinct lines over all distinct lines for file 2:", intersection_size / (intersection_size + file2_setdiff_size) > "/dev/stderr"
    print "Fraction of shared lines over all lines for file 1:", intersection_weight / (intersection_weight + file1_setdiff_weight) > "/dev/stderr"
    print "Fraction of shared lines over all lines for file 2:", intersection_weight / (intersection_weight + file2_setdiff_weight) > "/dev/stderr"
    print "Unweighted Jaccard Coefficient:", intersection_size / (intersection_size + file1_setdiff_size + file2_setdiff_size ) > "/dev/stderr"
    print "Weighted Jaccard Coefficient:", intersection_weight / (intersection_weight + file1_setdiff_weight + file2_setdiff_weight ) > "/dev/stderr"
}


#!/usr/bin/gawk -f

### uniq.awk
##
## A non-sort predicated unique entry filter alternative to 'uniq'.
## The total number of lines processed, and the number of unique lines, 
## are returned on a single line to stderr, separated by a tab character.
##
## The venerable 'uniq' command requires sorted input. This version does not.
## This was originally a code golf reply to:
## http://www.drbunsen.org/explorations-in-unix.html

### TODO:
## - Allow option to output counts along with each unique entry.
##   (and warn that this will buffer output)

BEGIN { OFS="\t" }

!_[$0]++ {count++; print}

END { print NR, count > "/dev/stderr" }
#!/usr/bin/gawk -f

### uniq.awk
###
### A non-sort predicated unique entry filter alternative to 'uniq'.
###
### The venerable 'uniq' command requires sorted input. This version does not.
### This was originally a code golf reply to:
### http://www.drbunsen.org/explorations-in-unix.html

### TODO:
### - Allow option to output counts along with each unique entry.
###   (and warn that this will buffer output)

!_[$0]++ {count++; print}
END { print NR, count > "/dev/stderr" }
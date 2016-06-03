#!/usr/bin/gawk -f

#### file2lisp_list.awk
##
## Take a file, and turn it into a Common Lisp list of symbols.

BEGIN { print "'(" }

/[a-z]+/ { print "|" $0 "|"; next }
{ print }

END { print ")" }

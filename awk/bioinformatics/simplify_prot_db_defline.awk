#!/usr/bin/gawk -f

### simplify_prot_db_defline.awk

## Given a protein database in FASTA format, replace the defline with a simple incrementor.
## Also saves out a mapping file of the incremented value, and the full previous defline.

/^>/ {

    incrementor++
    print ">lcl|" incrementor
    print incrementor, $0 > "/dev/stderr"
    next

}

1
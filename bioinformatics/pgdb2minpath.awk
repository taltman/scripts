#!/usr/bin/gawk -f

#### pgdb2minpath.awk
##
## Description:
## Given a PGDB's list of reactions and the MetaCyc reference pathway database, 
## create a MinPath formulation in glpsol format:
## https://en.wikibooks.org/wiki/GLPK/Knapsack_Problem

BEGIN { 
    FS=" - "
    OFS="\t"
}

## Load in reactions from PGDB (reactions.dat)
NR == FNR {

    if ( $0 !~ /^#/ && $1 == "UNIQUE-ID" ) {
	pgdb_rxns[$2]
	count++
    }
    next
}

## Processing MetaCyc's pathways.dat file:

!/^#/ && $1 == "UNIQUE-ID" {

    current_pwy = $2

}
 
!/^#/ && $1 == "REACTION-LIST" {
    curr_rxn_list[$2]

}

/^\/\// { 

    keep_pwy_p = 0
    for (rxn in curr_rxn_list)
	if ( rxn in pgdb_rxns )
	    keep_pwy_p = 1

    if (keep_pwy_p == 1) {
	meta_pwys[current_pwy]
	for ( rxn in curr_rxn_list ) {
	    meta_rxns[rxn]
	    meta_rxns_pwys[rxn,current_pwy]
	}
    }

    delete curr_rxn_list
    pwys++ 

}

END { 

    num_pwys = asorti(meta_pwys,pwy_array)
    num_rxns = asorti(pgdb_rxns,rxn_array)

    ## Print Variable Definitions:

    # for(i=1; i<=num_pwys; i++)
    # 	print "var p" i ", binary;"
    print "param N, integer;"
    print "set I := 1..N;"
    print "var p{i in I} binary;"

    ## Print Objective:

    # printf "minimize obj: p[1]"
    # for(i=2; i<=num_pwys; i++)
    # 	printf " + p[" i "]"
    # printf ";\n"

    print "minimize obj: sum{i in I} p[i];"

    ## Print constraints:
    
    for(i=1; i<=num_rxns; i++) {
	constraint_string = ""
	for(j=1; j<=num_pwys; j++)
	    if( (rxn_array[i],pwy_array[j]) in meta_rxns_pwys )
		constraint_string = constraint_string "p[" j "] + "
	if ( constraint_string != "" )
	    print "s.t. c" i ": " constraint_string "0 >= 1;"
    }
 
    ## Footer

    print "solve;"
    print "printf \"The min number of pathways is:\\n\";"
    print "printf \"%i\", obj;"
    print "printf \"\\n\";"
    print "printf \"The pathways involved are:\\n\";"
    print "printf {i in I: p[i] == 1} \"%i\\n\", i;"

    print "data;"
    print "param N := " num_pwys ";"

    print "end;"

    for(i=1; i<=num_pwys; i++)
	print pwy_array[i] > "pwy_list.txt"

    ##print count, pwys
}

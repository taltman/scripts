#!/usr/bin/gawk -f

## Given the output from kraken_trim_report, and a list of acceptable
## taxon IDs, create a mask defining good
## regions of the sequence.

## The basic algorithm is that when we are in a good region, we expand the
## end-bound of the region as long as we are in consecutive regions or
## overlapping regions 
## There could possibly be a few k-mers that are
## registered as bad, but are otherwise subsumed in a good region. We
## should be strict regarding possible contamination, and not allow such
## k-mers to remain.

BEGIN { 

    OFS="\t"

    if ( good_taxonids != "" ) {
	split(good_taxonids,good_taxa,",")
	for ( idx in good_taxa )
	    good_taxa[good_taxa[idx]] 
    }
    else {
	print "No taxa specified!"
	exit
    }
    
    ## Which regions should we report?
    if ( mask == "good" )
	mask = "good"
    else
	mask = "bad"

}

{ 
    contig[NR] = $2
    start_pos[NR] = $5
    end_pos[NR] = $6
    pos_taxon[NR] = $8
}

END {


    start_idx = 0

    previous_contig = contig[1]

    while (i <= NR ) { 
	##print "##", contig[i], start_pos[i], end_pos[i] 
	## Starting a new contig:
	if ( contig[i] != previous_contig ) {
	    if ( start_idx != 0 ) 
		print contig[i-1],start_idx,end_pos[i-1]
	    start_idx = 0
	    end_bad_region = 0
	}
	
	## Initialize the start index:
	if ( start_idx == 0 && pos_taxon[i] in good_taxa )
	    if( start_pos[i] > end_bad_region )
		start_idx = start_pos[i]
	    else
		start_idx = end_bad_region + 1

	    

	## Starting a bad region:
	if ( ! ( pos_taxon[i] in good_taxa ) ) {
	    end_bad_region = end_pos[i]
	    if ( start_idx != 0 ) 
		print contig[i],start_idx,start_pos[i]-1
	    start_idx = 0
	}

	previous_contig = contig[i]	
	i++

    }

    if ( start_idx != 0 )
	print contig[NR], start_idx, end_pos[NR]

}

#!/usr/bin/awk -f

## Example:
##  ~/repos/public_scripts/bioinformatics/mp-annots2contig-tax-ids.awk functional_and_taxonomic_table.txt > contig_taxa.txt

BEGIN { FS=OFS="\t" }

NR > 1 { 

    split($9,taxonid_parts,/[()]/)

    contig2taxids[$5] = contig2taxids[$5] "|" taxonid_parts[2]

}

END {

    for ( contig in contig2taxids ) {

	num_taxids = split(contig2taxids[contig],taxids,"|")

	printf contig
	for ( i = 2; i<= num_taxids; i++)
	    printf "\t" taxids[i]
	printf "\n"

    }

}
	

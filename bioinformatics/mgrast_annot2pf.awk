#!/usr/bin/gawk -f

#### mgrast_annot2pf.awk
##
## Convert a set of annotation files from MG-RAST API output to PathoLogic
## format
##
## TODO:
## * Allow the passing in of a list of defined bad contigs, or M5NR MD5
##   protein values, to exclude from the output
## 

## Inputs:
## 
## Inputs:
## -v taxonomy_db_path=/path/to/mgrast/taxonomy
## First file: list of contigs to not include in output.
## Second file: cluster file
## Third file: BLAT output file
## Fourth file: fasta file to split.
## Rest of files: organism, ontology, and functional annotation files.

### Example invocation:
## mg-rast-annot-download.sh 4575905.3 foo

## The list of bad contigs can be derived as follows:
## ~/projects/single-cell-assembly/code/mg-rast-contig-lca_v2.awk -v "taxonomy_db_path=$HOME/farmshare/bio_dbs/mg-rast/m5nr_taxonomy_2014-08-30.tsv" \
##                                                                -v "organism_annot_dir=$PWD" \
##          | ~/projects/single-cell-assembly/code/mg-rast-contig-lca-filter-policy.awk -v "taxonomy_db_path=$HOME/farmshare/bio_dbs/mg-rast/m5nr_taxonomy_2014-08-30.tsv" \
##               -v filter_out=good_contigs > bad_contig_list.txt

## mgrast_annot2pf.awk -v "taxonomy_db_path=$HOME/farmshare/bio_dbs/mg-rast/m5nr_taxonomy_2014-08-30.tsv" \
##                     bad_contig_list.txt \
##                     4575905.3.550.cluster.aa90.mapping \
##                     4575905.3.650.superblat.sims \
##                      ~/farmshare/single-cell-assembly-files/spades/ch1_nohuman/ch1_scaffolds_min125_no-outliers_mg_rast_formatted_headers.fa \
##                     *_annots.tsv


function pushDistinctValueSameKey (my_array, key, value) {

    if( !( key in my_array ))
	my_array[key] = value
    else if ( ! index(my_array[key], value) )
	my_array[key] = my_array[key] multi_value_array_sep value

}

BEGIN {
    FS = OFS = "\t" 

    while ( ( getline < taxonomy_db_path ) > 0 ) 	
	    orgname2taxonid[$8] = $9

    multi_value_array_sep = "|"

    split("",cluster2m5nr)
}



(NR%1000)==0 { print "mgrast_annot2pf: Processed " NR lines" raw annotation lines." > "/dev/stderr" }

NR == FNR { bad_contig[$1]; next }

## Process 550.cluster.aa90.mapping file:
ARGIND == 2 {

    num_loci = split($3,current_loci,",")
    current_loci[++num_loci] = $2

    for(locus_idx in current_loci) {

	num_parts = split(current_loci[locus_idx],locus_parts,"_")

	contig_name = locus_parts[1] "_" locus_parts[2]

	if( ! (contig_name in bad_contig) ) {
	    contigs[contig_name]
	    
	    if ( num_parts == 6 )
		## Example: ch1_99_[cov=1]_1_178_-
	    loci[contig_name,                                        ## contig ID
		 locus_parts[4], ## startbase
		 locus_parts[5], ## endbase
		 locus_parts[6], ## strand 
		 gensub(/.+cov=([0-9]+).+/,"\\1","g",locus_parts[3]), ## coverage info
		 $1]                                                 ## Corresponding cluster membership
	    else if ( num_parts == 7 )
		## Example: ch1_99__13423[cov=1]_1_178_-
	    loci[contig_name,                                        ## contig ID
		 locus_parts[5], ## startbase
		 locus_parts[6], ## endbase
		 locus_parts[7], ## strand 
		 gensub(/.+cov=([0-9]+).+/,"\\1","g",current_loci[locus_idx]), ## coverage info
		 $1]                                                 ## Corresponding cluster membership
	    else if ( num_parts == 8 ) 
		## Example: ch1_201__14463[cov=1]ID_401_1_175_+
	    loci[contig_name,                                        ## contig ID
		 locus_parts[6], ## startbase
		 locus_parts[7], ## endbase
		 locus_parts[8], ## strand 
		 gensub(/.+cov=([0-9]+).+/,"\\1","g",current_loci[locus_idx]), ## coverage info
		 $1]                                                 ## Corresponding cluster membership
	    else {
		print "mgrast_annot2pf.awk: Should not reach this state!" > "/dev/stderr"
		exit
	    }
	}
    }
    next
}


## Process 650.superblat.sims file:
ARGIND == 3 {

    pushDistinctValueSameKey(cluster2m5nr,$1,$2)
    next
}

## Process the FASTA file:
ARGIND == 4 && /^>/ {
    fasta_output_file = gensub(/^>(.*_[0-9]+)_.+/,"\\1","g",$1) ".fna"
}

ARGIND == 4 {
    print > fasta_output_file
    next
}

{ contig_name = gensub(/(.*)\|.*_([0-9]+)_.*/, "\\1_contig_\\2", "g", $1) }
## incorporate this filter:

!/Download/ && !/query sequence/ && !( contig_name in bad_contig ) {

    split($1,project_name,"|")    

    ## This figures out what kind of annotation to stash:
    if( FILENAME ~ /function/ ) 
	annot_type = "function"
    else if (FILENAME ~ /organism/ )
	annot_type = "organism"
    else if (FILENAME ~ /ontology/ ) {
	num_parts = split(FILENAME,path_parts,"/")
	num_tokens = split(path_parts[num_parts], tokens, "_")
	annot_type = tokens[1]
	databases[annot_type]
    }

    ## Load in M5NR identifiers:
    ##pushDistinctValueSameKey(contig_loci, contig_name SUBSEP $7 SUBSEP $8 SUBSEP "m5nr", $2)

    ## All other annotations get processed here:
    split($13,annots,";")
    for (annot_idx in annots) {
	pushDistinctValueSameKey(m5nr_annots, $2 SUBSEP annot_type, annots[annot_idx])

	## If we come across EC numbers, stash them away:
	if ( annots[annot_idx] ~ /EC[ :][0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ )
	    pushDistinctValueSameKey(m5nr_annots, $2 SUBSEP "EC", 
				     gensub(/.*[ :]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/,
					    "\\1","g",annots[annot_idx]))	
    }

}

END {     

    ## Print out an organism-init.dat file (though it may be ignored...)

    print "DOMAIN", "Bacteria" > "organism-init.dat"
    print "AUTHOR", "Noga Qvit-Raz" > "organism-init.dat"
    print "AUTHOR", "Tomer Altman:Stanford University" > "organism-init.dat"
    print "AUTHOR", "Paul C. Blainey:Broad Institute" > "organism-init.dat"
    print "AUTHOR", "Elisabeth M. Bik:Stanford University" > "organism-init.dat"
    print "AUTHOR", "David L. Dill:Stanford University" > "organism-init.dat"
    print "AUTHOR", "Stephen R. Quake:Stanford University" > "organism-init.dat"
    print "AUTHOR", "David A. Relman:Stanford University" > "organism-init.dat"
    print "EMAIL", "taltman1 AT stanford DOT edu" > "organism-init.dat"
    print "COPYRIGHT", "Copyright 2014 and onwards. Contact us for licensing terms." > "organism-init.dat"
    print "HOMEPAGE", "http://metagenomics.anl.gov/metagenomics.cgi?page=MetagenomeOverview&metagenome=" project_name[1] > "organism-init.dat"

    ## Print out the genetic-elements.dat file:

    for(contig_name in contigs) {
	print "ID", "mg_rast_" contig_name > "genetic-elements.dat"
	print "NAME", "Annotation file for MG-RAST contig " contig_name > "genetic-elements.dat"
	print "TYPE", ":CONTIG" > "genetic-elements.dat"
	print "CIRCULAR?", "N"  > "genetic-elements.dat"
	print "ANNOT-FILE", contig_name ".pf" > "genetic-elements.dat"
	print "SEQ-FILE", contig_name ".fna" > "genetic-elements.dat"
	print "//" > "genetic-elements.dat"
    }


    ## Iterate over all loci, and print out:
    max_id=0
    for(compound_key in loci) {

	split(compound_key,keys,SUBSEP)
	contig_name = keys[1]
	startbase = keys[2]
	endbase = keys[3]
	strand = keys[4]
	coverage = keys[5]
	cluster_id = keys[6]

	contig_file_name = contig_name ".pf"
	print "Writing " contig_file_name " ..." > "/dev/stderr"

	## Initial attributes:
	print "ID", "mg-rast_" ++max_id > contig_file_name
	print "PRODUCT-TYPE","P" > contig_file_name	
	print "STARTBASE", ( strand=="+" ) ? startbase : endbase > contig_file_name	
	print "ENDBASE",   ( strand=="+" ) ? endbase : startbase > contig_file_name	
	print "ABUNDANCE", coverage > contig_file_name

	## Set up array for iterating over all homologs for gene:
	split(cluster2m5nr[cluster_id],m5nr_prots,multi_value_array_sep)
	for( prot_idx in m5nr_prots) {
	    
	    ## Functional attributes:
	    split(m5nr_annots[m5nr_prots[prot_idx],"function"],functions,multi_value_array_sep)
	    for(func_idx in functions)
		print "FUNCTION", functions[func_idx] > contig_file_name
	}

	for( prot_idx in m5nr_prots) {
	    
	    split(m5nr_annots[m5nr_prots[prot_idx],"EC"],ecs,multi_value_array_sep)
	    for(ec_idx in ecs)
		print "EC", ecs[ec_idx] > contig_file_name
	}

	
	## Create gene comment, including a list of organisms where homologs were found:
	gene_comment = ". Taxonomic and functional annotatins are from the MG-RAST pipeline."
	org_list = ""
	for( prot_idx in m5nr_prots) {
	    split(m5nr_annots[m5nr_prots[prot_idx],"organism"],organisms,multi_value_array_sep)
	    for(org in organisms)
		org_list = org_list "; " organisms[org]
	}	    
	gene_comment = "Homologs for this gene were found in the following organisms: " substr(org_list,3) gene_comment
	if(org_list != "" ) print "GENE-COMMENT", gene_comment > contig_file_name
	    
	    
	## Create NCBI Taxonomy DBLINKs:
	for( prot_idx in m5nr_prots) {
	    split(m5nr_annots[m5nr_prots[prot_idx],"organism"],organisms,multi_value_array_sep)
	    for(org in organisms)
		if( organisms[org] in orgname2taxonid && orgname2taxonid[organisms[org]] )
		    print "DBLINK", "NCBI-TAXONOMY-DB:" orgname2taxonid[organisms[org]] > contig_file_name	
	}	    
	
	## Create M5NR dblinks:
	for( prot_idx in m5nr_prots)
	    print "DBLINK", "M5NR:" m5nr_prots[prot_idx] > contig_file_name	
			  
	    
	## Create Ontology dblinks:
	for(db in databases)
	    for( prot_idx in m5nr_prots) {
		split(m5nr_annots[m5nr_prots[prot_idx],db],dblinks,multi_value_array_sep)
		for(link_idx in dblinks)
		    print "DBLINK", db ":" dblinks[link_idx] > contig_file_name	
	    }
   
	print "//" > contig_file_name

    } ## end for loop over loci

}


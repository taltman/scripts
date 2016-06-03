#!/usr/bin/gawk -f

## Example: 
##  time ../code/map2enz_rel_abun_tbl.awk trophism_KO_uniprot.txt ~/farmshare/guilds/protein_dbs/indicator_proteins_v1.fsa sample_sizes.txt metahit_reads/*.m8 > uniprot_vs_metahit_n51.tsv


## Supported policies for computing abundance from read hits:
## * none: count up all reads
## * discard_dupes: multi-hit reads are discarded
## * best_hit: only count the best hit
## * split_vote: count all, but scale by number of hits
## * HUMAnN: split vote, scaled by p-value, normalized by gene length:
## * sample_size: scale results based on sample size vs. average sample size

BEGIN { 

    FS = OFS = "\t" 
    
    if ( policy == "")
	policy = "HUMAnN"

    ## RAPSearch2 returns the log of the e-value
    ## So, larger value means worse match. Smaller (i.e., more negative)
    ## value is a better match.
    ## I forget which base log they use, so I just plotted histogram of
    ## values:
    ## Upper elbow at log(e_value) ~ -2, so use that as cutoff:
    if ( max_log_evalue == "")
	max_log_evalue == -2

}

## First argument: trophism_KO_uniprot.txt
NR == FNR && !$4{ 
    
    enz_order[FNR] = $3
    enz_trophism[$3] = $1
    if ( ! trophism[$1]++ )
	trophism_order[++order_count] = $1
    trophism_size[$1]++
    num_enzymes = FNR
    next 
}

## Second argument: indicator_proteins_v1.fsa
ARGIND == 2 && /^>/ {

    split($0,defline_parts,"|")
    current_accession = defline_parts[2]
    next
}

ARGIND == 2 {
    
    enzyme_length[current_accession] += length($0)
    next
}

## sample_sizes.txt
ARGIND == 3 {

    split($1,file_parts,"/")
    sample_size[file_parts[2]".out.m8"] = $2
    total_sample_size += $2
    average_sample_size = total_sample_size / FNR
    next

}

## Next arguments: m8 output from RAPSearch2:
## I need to specify the ARGIND here, because otherwise the pesky
## trophism_KO_uniprot.txt line with a fourth column will pollute the samples array:
ARGIND > 3 && ! /^#/ && $11 <= max_log_evalue {

    samples[FILENAME]++

    split($2,id_parts,"|")

    p_value = 1 - exp(-exp($11))

    if ( policy == "HUMAnN" )
	read_penalty[FILENAME,$1] += 1 - p_value

    read_enzyme[FILENAME,$1,id_parts[2]] = (policy=="HUMAnN") ? 1 - p_value : 1

}

END {

    ## Print column headers:
    num_samples = asorti(samples,sorted_samples)
    
    for(i=1; i<= num_samples; i++) {
	num_parts = split(sorted_samples[i],name_parts,"/")
	printf "\t" name_parts[num_parts]
    }
    print ""

    ### Normalize enzymes by read counts:

    ## Step 1: Loop over trophisms:
    for(i=1; i<=order_count; i++) {

	current_trophism = trophism_order[i]	
	printf current_trophism

	## Step 2: Loop over Samples:
	for(j=1; j<=num_samples; j++) {
	    sample_name = sorted_samples[j]
	    	
	    current_trophism_weight = 0

	    ## Step 3: Loop over enzymes:
	    for(k=1; k<=num_enzymes; k++) {
		uniprot_id = enz_order[k]

		if ( enz_trophism[uniprot_id] == current_trophism ) {
			    
		    ## Step 4: Loop over reads:
		    current_enzyme_weight=0
		    current_read_penalty=0
		    num_hits=0
		    for(combined_key in read_enzyme) {
			
			split(combined_key,keys,SUBSEP)
			if( keys[1] == sample_name && keys[3] == uniprot_id) {
			    num_hits++
			    current_read_penalty = read_penalty[keys[1],keys[2]]

			    if ( policy!="HUMAnN" )
				current_enzyme_weight += read_enzyme[combined_key]
			    else if ( current_read_penalty )
				current_enzyme_weight += read_enzyme[combined_key] / current_read_penalty
				
			}
		    }
	

		    ## Enzyme weights are scaled by p-value, summed over reads, and scaled by length:		    
		    ##print current_enzyme_weight, uniprot_id, enzyme_length[uniprot_id]
		    if( policy != "HUMAnN")
			current_trophism_weight += current_enzyme_weight 
		    else
			current_trophism_weight += current_enzyme_weight / enzyme_length[uniprot_id]
		
		    ##print FS current_enzyme_weight, current_read_penalty, num_hits, enzyme_length[uniprot_id], enzyme_weight
		    
		} ## end if enzyme of current trophism

	    } ## end loop over enzymes

	    if( policy=="sample_size" )
		printf FS current_trophism_weight * (average_sample_size/sample_size[sample_name])
	    else
		printf FS current_trophism_weight
	    current_trophism_weight = 0

	} ## end loop over samples
	print ""
		    
    } ## end loop over enzymes

}

#     for(i=1; i<=num_enzymes; i++) {
# 	uniprot_id = enz_order[i]
# 	printf uniprot_id
	
# 	for(j=1; j<=num_samples; j++) {
# 	    sample_name = sorted_samples[j]
# 	    rel_abun_enzyme = sample_enzyme[uniprot_id,sample_name]/samples[sample_name]
# 	    printf "\t" rel_abun_enzyme
# 	}
	
# 	print ""

#     }

# }
	


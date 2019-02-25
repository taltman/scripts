#!/usr/bin/gawk -f

#### seqsim2rel_abun.awk
##
## Description:
##
## Take sequence similarity computation results in Blast tabular output
## format (-m 8, produced by Blast, Blast+, RAPSearch2, Diamond, etc.),
## and compute relative abundances for the target sequences.
## 
## Example:
## time seqsim2rel_abun.awk -v sample_names=test,test2 \
##                          -v paired_end_hits_policy="best_end" \
##                          -v db_fasta_file=$HOME/farmshare/bio_dbs/metacyc/18.0/data/uniprot-seq-ids_ptools_v18.faa \
##                          <(diamond view -a MH0002_081203_clear.1.daa) \
##                          <(diamond view -a MH0002_081203_clear.2.daa ) \
##                          > MH0002_081203_clear_rel_abun.txt 
##
##
## Details:
##
## If given more than one file to process, it will be assumed that there
## are multiple unpaired read files to process. 
## If given the -v paired_end_reads_p=1 and exactly two files are
## provided, then it will be assumed that the 
## reads are paired-end, and that the "first" (usually the forward) reads
## are in the first file, and the "second" (usually the reverse) reads are
## in the second file.
##
## Example: 
## time seqsim2rel_abun.awk read1.rapsearch2.m8 read2.rapsearch2.m8 > uniprot_vs_metahit_n51.tsv
##
## Arguments:
## -v multihit_policy: See available values below. Default: HUMAnN
## -v paired_end_hits_policy: See available values. Must be set to process
##    paired end data. Default: best_end.
## -v db_fasta_file: File path to target reference database in FASTA
##    format. The sequence deflines must either be a simple target
##    sequence identifier following the ">" at the start of the line, or
##    in the extended NCBI format: ">gi|{accession}|..."
##    If provided, will be used for computing the length per target
##    sequence, and then for normalizing the hits for a target sequence.
## -v max_log_evalue: In case the sequence similarity computation doesn't
##    allow filtering, this may be used to specify a max log e-value
##    value. Anything with a larger e-value than this value will not be
##    used for computing relative abundance. Default: -3
## -v sample_names: A comma-delimited list of sample names. Optional.

## Supported policies for computing abundance from reads with more than
## one hit (multihit_policy):
## (note that for now, this also applies to multiple read hits to the same
## target sequence)
## * none: count up all reads
## * discard_dupes: multi-hit reads are discarded
## * split_vote: count all, but scale by number of hits
## * HUMAnN: split vote, scaled by p-value


## Supported policies for dealing with a paired end having both mate pairs
## hitting a target sequence (paired_end_hits_policy). 
## * none: Treat second file as if it were unrelated (i.e. a separate sample)
## * best_end: The best hit of the two ends will count


## TODO:
## * Provide more options for how to deal with multiple read hits to the
##   same target sequence.
## * Instead of getting sizes from FASTA file, accept file of weights to
##   be used for normalizing target sequence hits. More flexible.
## * Provide option to dump summary statistics to stderr or specified
##   file.
## * Implement the following multihit_policy:
##   best_hit: only count the best hit

function increase_read_penalty (filename,read_id,read_contribution) {

    if ( multihit_policy == "HUMAnN" || multihit_policy == "split_vote" )
	read_penalty[filename,read_id] += read_contribution
    read_penalty[filename,read_id,"size"]++

}

function set_read_contribution (filename,target,read_id,read_contribution) {
    ##print filename,target,read_id,read_contribution
    curr_idx = ++sample_target[filename,target,"size"]
    sample_target[filename,target,curr_idx,"read_id"] = read_id
    sample_target[filename,target,curr_idx,"value"] = read_contribution

}

function log10 (num) { 
    return log(num)/log(10) 
}

BEGIN { 

    FS = OFS = "\t" 

### Error-checking of inputs:

### Set default values:

    if ( multihit_policy == "")
	multihit_policy = "HUMAnN"

    if ( paired_end_hits_policy == "")
	paired_end_hits_policy = "none"

    if ( max_log_evalue == "")
	max_log_evalue = -3
    
    if (sample_names != "") {
	num_samples=split(sample_names,sample_labels,",")
	if ((ARGC==1 && ARGC==num_samples) || (ARGC>1 && num_samples != (ARGC-1)))
	    print "Error: number of sample labels (" num_samples ") does not equal the number of files provided (" ARGC ")." >> "/dev/stderr"
	if(paired_end_hits_policy!="none")
	    num_samples--

    }


### Process FASTA file for sequence lengths:

    accession_index = 0
    while ( (getline < db_fasta_file ) > 0 ) {

	if ( $0 ~ /^>/ ) {
	    split($0,defline_parts," ")
	    current_accession = substr(defline_parts[1],2)
	    accessions[++accession_index] = current_accession
	}
	else
	    sequence_length[current_accession] += length($0)
    }

}



## Pattern/Actions for m8 output 

{ 
    if ( ARGC == 1)
	file_index = 1
    else
	file_index = ARGIND
    current_filename = sample_labels[file_index] 
}

##{ print ARGIND, ! /^#/, log10($11), max_log_evalue }
file_index == 1 && ! /^#/ && log10($11) <= max_log_evalue {
  
    samples[current_filename]++

    ##split($2,id_parts,"|")

    p_value = 1 - exp(-exp($11))

    read_contribution = ((multihit_policy=="HUMAnN") ? 1 - p_value : 1) 

    increase_read_penalty(current_filename,$1,read_contribution)
        
    set_read_contribution(current_filename,$2,$1,read_contribution)
    
}

file_index == 2 && paired_end_hits_policy == "best_end" && ! /^#/ && log10($11) <= max_log_evalue {
    
    read_id=""

    previous_filename=sample_labels[file_index-1]
    if ( (previous_filename,$1) in read_penalty )
	read_id = $1
    test_read_id = gensub(/(.*)2$/,"\\1""1","g",$1)
    if ( (previous_filename,test_read_id) in read_penalty )
	read_id = test_read_id

    p_value = 1 - exp(-exp($11))
    read_contribution = ((multihit_policy=="HUMAnN") ? 1 - p_value : 1) 


    if (read_id) {
	
	num_target_reads = sample_target[previous_filename,$2,"size"]
	for(i=1; i<= num_target_reads; i++)
	    if ( sample_target[previous_filename,$2,i,"read_id"] == read_id )
		previous_contribution = sample_target[filename,$2,i,"value"]

	if ( read_contribution > previous_contribution ) {

	    set_read_contribution(previous_filename,$2,read_id,read_contribution)

	    read_penalty[previous_filename,read_id] -= previous_contribution
	    increase_read_penalty(previous_filename,read_id,read_contribution)
        
	}

    } else {
	
	increase_read_penalty(previous_filename,$1,read_contribution)
        
	set_read_contribution(previous_filename,$2,$1,read_contribution)

    }
	
	
}

END {

    ## Print column headers:

    for(i=1; i<=accession_index; i++)	    
	printf "\t" accessions[i]
    print ""

    
    ### Normalize enzymes by read counts:

    ## Step 1: Loop over Samples:
    for(j=1; j<=num_samples; j++) {
	sample_name = sample_labels[j]
	printf sample_name
	
	## Step 2: Loop over target sequences
	for(i=1; i<=accession_index; i++) {
	    
	    current_accession = accessions[i]
	    target_normalization = ( db_fasta_file ? sequence_length[current_accession] : 1 )
	    
	    num_reads_for_target = sample_target[sample_name,current_accession,"size"]
	    for (k=1; k<= num_reads_for_target; k++) {
		read_contribution = sample_target[sample_name,current_accession,k,"value"]
		curr_read_id = sample_target[sample_name,current_accession,k,"read_id"]
		curr_read_penalty = ( multihit_policy != "none") ?  read_penalty[sample_name,curr_read_id] : 1
		
		if ( ! ( multihit_policy == "discard_dupes" && read_penalty[sample_name,curr_read_id,"size"] > 1 ))
		    sample_target[sample_name,current_accession,"sum"] += read_contribution/curr_read_penalty
	    }
	    
	    printf "\t" (sample_target[sample_name,current_accession,"sum"]/target_normalization)

	}
	print ""
	
    } ## end loop over samples
    
}


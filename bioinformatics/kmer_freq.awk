#!/usr/bin/gawk -f

### kmer_freq.awk: Compute the kmer frequency for a FASTA-formatted file
### TODO:
## * Compute all possible k-mers up front, so that we can stream output
##   instead of having it block by only printing at the end.
## * Make strand-bias method from Banfield et al optional

function analyze_sequence_by_chunk (seq_id, seq_coverage, seq_length, sequence,
				    chunk) {

    if ( chunk_length == 0 || length(sequence) < chunk_length )
	compute_sequence_kmer_freq(seq_id, seq_coverage, seq_length, sequence)
    else
	
	for(i=0; i< int(length(sequence)/chunk_length)+1; i++) {
	    chunk = substr(sequence,i*chunk_length+1,chunk_length)
	    if ( length(chunk) >= min_sequence_length )
		compute_sequence_kmer_freq(seq_id "_chunk_" i, seq_coverage, seq_length, chunk)
	}

}

function compute_sequence_kmer_freq (seq_id, seq_coverage, seq_length, sequence,
				     i, kmer, num_kmers, reverse_complement_kmer, smallest_kmer,nucleotides,idx) {



    ## How many sliding k-length windows in string:
    num_windows = length(sequence) - k + 1
    
    global_seq_id_array[seq_id] = num_windows

    if ( coverage_p && seq_coverage )
	global_seq_coverage_array[seq_id] = seq_coverage

    if ( length_p && seq_length )
	global_seq_length_array[seq_id] = seq_length


    if ( gc_p ) {

	split(sequence,nucleotides,"")
	for(idx in nucleotides)
	    if ( nucleotides[idx] == "G" || nucleotides[idx] == "C" )
		sequence_kmer_array[seq_id,"GC"]++
	global_kmer_array["GC"]
		
    }
	

    for(i=0; i< num_windows; i++){ 

	kmer = substr(sequence,i,k)
	
	## According to Dick, Banfield, et al., 2009 paper, should sum
	## kmer and its reverse complement to same pile, to avoid strand
	## bias.
	## So, we pick the kmer that sorts to the lowest index to contain
	## the contributions from both:

	## If we are ignoring 'N' as a base, and the current kmer has an
	## 'N', skip it:
	if ( n_base_p == 1 || kmer !~ /N/ ) {
	    reverse_complement_kmer = reverse_complement(kmer)
	    
	    smallest_kmer = ( kmer < reverse_complement_kmer ) ? kmer : reverse_complement_kmer
	    
	    sequence_kmer_array[seq_id,smallest_kmer]++
	}

    }

}

### According to Dick, ... Banfield 2009, you should sum up the
### contributions from the reverse complement kmer, to avoid strand
### bias. Thus, we need a reverse complement function:
### Furthermore, we memoize this function to trade off memory for
### increased performance:

function reverse_complement (sequence,
			     reverse_complement_sequence, sequence_array) {

    if ( sequence in kmer_reverse_complement_array )
	return kmer_reverse_complement_array[sequence]
    else {
	
	split(sequence,sequence_array,"")
	
	for(i=length(sequence); i>0; i--)
	    reverse_complement_sequence = reverse_complement_sequence base_pairing[sequence_array[i]]
	
	kmer_reverse_complement_array[sequence] = reverse_complement_sequence
	kmer_reverse_complement_array[reverse_complement_sequence] = sequence

	return reverse_complement_sequence

    }
	
}

## Generate all possible kmers:

function make_kmers(partial_kmer,depth) {

    if(depth==k)
	for (base in base_pairing) {
	    kmer = partial_kmer base

	    reverse_complement_kmer = reverse_complement(kmer)

	    smallest_kmer = ( kmer < reverse_complement_kmer ) ? kmer : reverse_complement_kmer

	    if ( ! ( smallest_kmer in global_kmer_array ))
	    	global_kmer_array["size"]++
	    global_kmer_array[smallest_kmer]
	    
	}
    else
	for (base in base_pairing)
	    make_kmers(partial_kmer base,
		       depth+1)
}

BEGIN {

    ### Global variables:
    LINT=0

    ## This should be settable from the command line:
    if (k=="") k = 4

    ## Data format ("Databionic" or "R"):
    if (output_format=="") output_format = "Databionic"
    #output_format = "R"

    ## Freq or density?
    ## Return tetranucleotide counts, or fraction of contig length?
    if (density_p=="") density_p = 1

    ## Min sequence length:
    ## Set to '0' to deactivate.
    if (min_sequence_length=="") min_sequence_length = 2000

    ## Chunk length:
    ## To avoid bias from sequence length, we break the contig into chunks
    ## Set to '0' to deactivate.
    if (chunk_length=="") chunk_length = 5000

    ## Use coverage?
    ## If FASTA defline includes coverage information, include it?
    if (coverage_p=="") coverage_p = 0

    ## Use length?
    ## If FASTA defline includes length information, include it?
    if (length_p=="") length_p = 0

    ## Compute GC%?
    if (gc_p=="") gc_p = 0

    ## Recognize 'N' as base?
    if (n_base_p=="") n_base_p = 0



### Global variables:
    
    ## For enumerating the number of possible kmers, and for computing the reverse-complement:
    
    split("",base_pairing)

    base_pairing["A"] = "T"
    base_pairing["T"] = "A"
    base_pairing["C"] = "G"
    base_pairing["G"] = "C"
    if(n_base_p == 1)
	base_pairing["N"] = "N"


    ## For sorting the arrays sensibly:
    split("",global_kmer_array)

    ## For sorting the sequence IDs:
    split("",global_seq_id_array)

    ## For including coverage information:
    split("",global_seq_coverage_array)

    ## For including length information:
    split("",global_seq_length_array)
    
    ## Table of sequence, kmer tuples:
    split("",sequence_kmer_array)

    ## Memoize computation of reverse-complement:
    split("",kmer_reverse_complement_array)

    
    ## Generate all kmers:
    make_kmers("",1)
    ##print global_kmer_array["size"] >> "/dev/stderr"

    
}

## toupper to make sure all bases are in upper case:
$0 !~ /^>/ { current_sequence = current_sequence toupper($0); next }

NR!=1 && length(current_sequence) >= min_sequence_length { 

    ## Catch bizarre base characters:
    if( current_sequence !~ /[ACTGN]+/ ) { 
	print "Error in sequence before line " FNR " (ID " current_seq_id " ): unrecognized base character. Sequence below:" >> "/dev/stderr"
	print current_sequence >> "/dev/stderr"
	exit
    }

    analyze_sequence_by_chunk(current_seq_id,
			      current_coverage,
			      current_length,
			      current_sequence) }
{ 
    
    sub(/^>/,"")    
    split($0,defline_parts,"_")
    
    if ( defline_parts[1] == "NODE" )
	current_seq_id = defline_parts[1] "_" defline_parts[2]
    else
	current_seq_id = $0

    if ( coverage_p && defline_parts[5] == "cov" )
	current_coverage = defline_parts[6]

    if ( length_p && defline_parts[3] == "length" )
	current_length = defline_parts[4]

    current_sequence = ""

}



END {

    ## One last sequence to process:
    if ( length(current_sequence) > min_sequence_length )
	analyze_sequence_by_chunk(current_seq_id,
				  current_coverage,
				  current_length,
				  current_sequence)

    global_kmer_array_size = global_kmer_array["size"]
    asorti(global_kmer_array)
    
    ##for (idx in global_seq_id_array)
##	sort_seq_ids_array[idx] = global_seq_id_array[idx]
    
    num_seq_ids = asorti(global_seq_id_array,sort_seq_ids_array)

    ## Print column header row:
    idx = 0
    while (++idx in global_kmer_array)
	if ( global_kmer_array[idx] != "size" )
	    if ( output_format == "Databionic" && idx == 1 )
		printf "%% " global_kmer_array[idx]
	    else
		printf "\t" global_kmer_array[idx]    
    printf coverage_p  ? "\tCOVERAGE" : ""
    printf length_p  ? "\tLENGTH" : ""
    printf "\n"


    ## For Databioinic ESOM, print out *.cls header:
    if ( output_format == "Databionic" )
	print "% " num_seq_ids > "databionic_object.names"


    ## Print rest of table, with row labels:

    for (seq_idx=1; seq_idx <= num_seq_ids; seq_idx++) {

	## First clause: # of kmer
	tetranuc_denominator = density_p ?  global_seq_id_array[sort_seq_ids_array[seq_idx]] : 1

	## Second clause: length of contig:
	gc_denominator = density_p ? global_seq_id_array[sort_seq_ids_array[seq_idx]] + k - 1 : 1


	if ( output_format != "Databionic")
	    printf sort_seq_ids_array[seq_idx]
	else
	    print seq_idx "\t" sort_seq_ids_array[seq_idx] "\t" sort_seq_ids_array[seq_idx] > "databionic_object.names"

	kmer_idx = 0
	while (++kmer_idx in global_kmer_array) {
	    if ( global_kmer_array[kmer_idx] != "size" ) {


		##print seq_id, sort_seq_ids_array[seq_id], global_seq_id_array[sort_seq_ids_array[seq_id]] >> "/dev/stderr"
		##print gc_p, density_p, "|" global_kmer_array[idx]"|", tetranuc_denominator, gc_denominator >> "/dev/stderr"		

		datum = (sequence_kmer_array[sort_seq_ids_array[seq_idx],
					     global_kmer_array[kmer_idx]] + 0) / (( global_kmer_array[kmer_idx] == "GC" ) ? gc_denominator : tetranuc_denominator )

		printf ( output_format != "Databionic") ? ("\t" datum ) : 
		    ( ( kmer_idx == global_kmer_array_size ) ? datum : (datum "\t"))
	    }
	}
	printf coverage_p ? ("\t" global_seq_coverage_array[sort_seq_ids_array[seq_idx]]) : ""
	printf length_p ? ("\t" global_seq_length_array[sort_seq_ids_array[seq_idx]]) : ""
	printf "\n"
    }

} 
	    
	


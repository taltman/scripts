#!/usr/bin/gawk -f

### aa2nt.awk
##
## Description:
##
## Reverse-transcribes an amino acid FASTA formatted file into a nucleotide FASTA formatted file, 
## by assigning a random codon (from the Standard Code codon table; to be precise, transl_table=1) for each residue.
##
## See:
## https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c
## 
## TODO:
## * Add ability to use alternate codon tables
## * Add ability to provide weights to different codons, so that the random selection is proporitional to the weights.
## * Find more clever way of storing codon tables, instead of boilerplate multidimensional array storage.

BEGIN {

    ## codon_table: Stores the Standard Codon in a multidimensional array, 
    ## along with the number of codons for a given residue under the key "size":

    codon_table["F", 1] = "TTT"
    codon_table["F", 2] = "TTC"
    codon_table["F", "size"] = 2
    codon_table["L", 1] = "TTA"
    codon_table["L", 2] = "TTG"
    codon_table["L", 3] = "CTT"
    codon_table["L", 4] = "CTC"
    codon_table["L", 5] = "CTA"
    codon_table["L", 6] = "CTG"
    codon_table["L", "size"] = 6
    codon_table["I", 1] = "ATT"
    codon_table["I", 2] = "ATC"
    codon_table["I", 3] = "ATA"
    codon_table["I", "size"] = 3
    codon_table["M", 1] = "ATG"
    codon_table["V", 1] = "GTT"
    codon_table["V", 2] = "GTC"
    codon_table["V", 3] = "GTA"
    codon_table["V", 4] = "GTG"
    codon_table["V", "size"] = 4
    codon_table["S", 1] = "TCT"
    codon_table["S", 2] = "TCC"
    codon_table["S", 3] = "TCA"
    codon_table["S", 4] = "TCG"
    codon_table["S", "size"] = 4
    codon_table["P", 1] = "CCT"
    codon_table["P", 2] = "CCC"
    codon_table["P", 3] = "CCA"
    codon_table["P", 4] = "CCG"
    codon_table["P", "size"] = 4
    codon_table["T", 1] = "ACT"
    codon_table["T", 2] = "ACC"
    codon_table["T", 3] = "ACA"
    codon_table["T", 4] = "ACG"
    codon_table["T", "size"] = 4
    codon_table["A", 1] = "GCT"
    codon_table["A", 2] = "GCC"
    codon_table["A", 3] = "GCA"
    codon_table["A", 4] = "GCG"
    codon_table["A", "size"] = 4
    codon_table["Y", 1] = "TAT"
    codon_table["Y", 2] = "TAC"
    codon_table["Y", "size"] = 2
    codon_table["*", 1] = "TAA"
    codon_table["*", 2] = "TAG"
    codon_table["*", 3] = "TGA"
    codon_table["*", "size"] = 3
    codon_table["H", 1] = "CAT"
    codon_table["H", 2] = "CAC"
    codon_table["H", "size"] = 2
    codon_table["Q", 1] = "CAA"
    codon_table["Q", 2] = "CAG"
    codon_table["Q", "size"] = 2
    codon_table["N", 1] = "AAT"
    codon_table["N", 2] = "AAC"
    codon_table["N", "size"] = 2
    codon_table["K", 1] = "AAA"
    codon_table["K", 2] = "AAG"
    codon_table["K", "size"] = 2
    codon_table["D", 1] = "GAT"
    codon_table["D", 2] = "GAC"
    codon_table["D", "size"] = 2
    codon_table["E", 1] = "GAA"
    codon_table["E", 2] = "GAG"
    codon_table["E", "size"] = 2
    codon_table["C", 1] = "TGT"
    codon_table["C", 2] = "TGC"
    codon_table["C", "size"] = 2
    codon_table["W", 1] = "TGG"
    codon_table["W", "size"] = 1
    codon_table["R", 1] = "CGT"
    codon_table["R", 2] = "CGC"
    codon_table["R", 3] = "CGA"
    codon_table["R", 4] = "CGG"
    codon_table["R", 5] = "AGA"
    codon_table["R", 6] = "AGG"
    codon_table["R", "size"] = 6
    codon_table["S", 1] = "AGT"
    codon_table["S", 2] = "AGC"
    codon_table["S", "size"] = 2
    codon_table["G", 1] = "GGT"
    codon_table["G", 2] = "GGC"
    codon_table["G", 3] = "GGA"
    codon_table["G", 4] = "GGG"
    codon_table["G", "size"] = 4
    
    _cliff_seed = rand()

}

## As taken from the Gawk Manual:
## (Improves on standard C library rand() function)

function cliff_rand() {

    _cliff_seed = (100 * log(_cliff_seed)) % 1
    if (_cliff_seed < 0 )
	_cliff_seed = - _cliff_seed
    return _cliff_seed

}


## Pick a random integer from 1 to N (inclusive):
function randint(n) {
    return int(n * cliff_rand())+1
}


### Main:

! /^>/ {

    ## Split residues into an array, and count the length:
    num_residues = split($0,residues,"")

    ## For each residue, convert it into a random codon:
    for (i=1; i <= num_residues; i++) {
	
        ## Force inputs to be capitalized for hash lookup
	residue = toupper(residues[i]) 

	## Pick an index for the random codon
	random_codon_index = randint(codon_table[residue,"size"]) 

	## Print the random codon
	printf "%s", codon_table[residue, random_codon_index] 
    }

    printf "\n"
			
    next
    
}	  

1


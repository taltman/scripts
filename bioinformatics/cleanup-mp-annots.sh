#!/bin/bash

#### cleanup-mp-annots.sh
##
## Description:
##
## MetaPathways v2.5 currently does a sub-standard job of preparing
## data file for use with Pathway Tools. Specifically, it doesn't
## provide sequence data nor regulon definitions, so it is impossible
## to predict operons, obtain gene/protein sequences from within the
## GUI, etc. These are all easy-to-do, if only done correctly.
##
## Run from the "new" PGDB version's 'input' directory, like so:
##
## cd /Users/taltman/ptools-local/pgdbs/user/tm7_ch1cyc/0.1.1/input
## cleanup-mp-annots.sh scaffolds.unannot.gff gene-locus-id2rxn.dat 0.pf scaffolds.fasta
##
##
## Steps needed to incorporate these changes in PTools:
##
## 1. Download scaffolds.unannot.gff and scaffolds.fasta
## 2. Get list of ORF ID to MetaCyc rxns from old version, turn into METACYC attributes.
##    Compare enzrxns of old and new versions, make sure not missing any associations.
## 2. Reinitialize the DB
## 3. Run this script
## 4. Run Trial Parse
## 5. Run Build
## 6. Run TU Predictor
## #. Run Protein Complex predictor
## #. Build nt and aa Blast DBs.
## #. Run TIP and accept suggested transporters.
## 8. Compare pwys of old and new versions, make sure we are not missing any pwys. This will create a list to put into MetaCyc answer list for importing to TM7:
## diff <(egrep "^UNIQUE-ID" ../../0.1/data/pathways.dat | sort) <(egrep "^UNIQUE" ../data/pathways.dat | sort ) 
##    diff <(egrep "^UNIQUE-ID" ../../0.1/data/pathways.dat | sort) \
##         <(egrep "^UNIQUE" ../data/pathways.dat | sort ) | \
##         grep UNIQUE | awk -F" - " '{ print $2 }'
## 9. Run Hole Filler
## 10. Rebuild overview.
## 
## #. Re-run TU Predictor after rescoring pathways

gff_file="$1"
orf_rxn_file="$2"
old_annot_file="$3"
assembly_fasta="$4"




## Break up 0.pf into the component contig annotation files:

awk 'BEGIN { FS=OFS="\t" }

## Process GFF file to get correct gene coordinates:
NR == FNR {
   split($9,tags,"[;=]")
   id = tags[2]
   if( $7 == "+" ) {
      id2startbase[id] = $4
      id2endbase[id]   = $5
   } else {
      id2startbase[id] = $5
      id2endbase[id]   = $4
   }
   next
}

   ## Loading ORF id to MetaCyc rxn mapping 
   ## (This data is from first version of PGDB being updated)

## This cannot be done, because different assembly has different genes, potentially. Furthermore,
## the MP2 scaffold renaming between runs is not a stable mapping. 
## Retain the file, and resort to annotation matching, sequence matching or BLAST-ing 
## if key reactions are not rediscovered.

##FILENAME ~ /dat$/ { gsub("scaffolds_","scaffolds_filtered_",$1); orf2rxns[$1]=$0; next }

$0 == "//" { 
  split(curr_record["ID"],scaffold_name_parts,"_")
  scaffold_name = scaffold_name_parts[1] "_" scaffold_name_parts[2] "_" scaffold_name_parts[3]

  scaffolds[scaffold_name]

  ## Print record to correct file  

  if ( "ID" in curr_record )
     print "ID", curr_record["ID"] >> (scaffold_name ".pf")
  if ( "NAME" in curr_record )
     print "NAME", curr_record["NAME"] >> (scaffold_name ".pf")
  if ( curr_record["ID"] in id2startbase )
     print "STARTBASE", id2startbase[curr_record["ID"]] >> (scaffold_name ".pf")
  if ( curr_record["ID"] in id2endbase )
     print "ENDBASE", id2endbase[curr_record["ID"]] >> (scaffold_name ".pf")
  if ( "PRODUCT" in curr_record )
     print "PRODUCT", curr_record["PRODUCT"] >> (scaffold_name ".pf")
  if ( "PRODUCT-TYPE" in curr_record && curr_record["PRODUCT"] ~ /^tRNA/ )
     print "PRODUCT-TYPE", "TRNA" >> (scaffold_name ".pf")
  else if ( "PRODUCT-TYPE" in curr_record && ( curr_record["PRODUCT"] ~ /rRNA/ || curr_record["PRODUCT-TYPE"] ~ /Ribosomal RNA/ ) )
     print "PRODUCT-TYPE", "RRNA" >> (scaffold_name ".pf")
  else if ( "PRODUCT-TYPE" in curr_record )
     print "PRODUCT-TYPE", "P" >> (scaffold_name ".pf")
  if ( "EC" in curr_record )
     print "EC", curr_record["EC"] >> (scaffold_name ".pf")

  ## If there are MetaCyc Rxn associations, import them here:
  if ( curr_record["ID"] in orf2rxns ) {
     num_rxns = split(orf2rxns[curr_record["ID"]], rxns, "\t")
     for(i=2; i<=num_rxns; i++)
        print "METACYC", rxns[i] >> (scaffold_name ".pf")
  }

  ## End the record:
  print "//" >> (scaffold_name ".pf") 

## To avoid using up all open file handles:
close(scaffold_name ".pf")
## Clear the current record, getting ready for the next one
delete curr_record
next }

{ curr_record[$1] = $2 }

END { 
  
   for (scaffold in scaffolds) {
        ## Print entry in genetic-elements.dat
        print "ID", scaffold > "genetic-elements.dat"
        print "NAME", scaffold > "genetic-elements.dat"
        print "TYPE", ":CONTIG" > "genetic-elements.dat"
        print "ANNOT-FILE", (scaffold ".pf") > "genetic-elements.dat"
        print "SEQ-FILE", (scaffold ".fna") > "genetic-elements.dat"
        print "//" > "genetic-elements.dat"
   }

}' $gff_file $orf_rxn_file $old_annot_file





## Break up multi-FASTA file into components:

awk -F">" '(NR % 2) == 1 { defline = $2 }
(NR % 2) == 0 {
   print ">" defline > ( defline ".fna" )
   print $0 > ( defline ".fna" )
   close( defline ".fna" )
}' $assembly_fasta
   

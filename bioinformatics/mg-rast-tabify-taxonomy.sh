#!/bin/bash

mg_rast_json_taxon_file="$1"

sed 's/{"domain/\n{"domain/g' < $mg_rast_json_taxon_file \
    | sed 's/},{/},\n{/g' \
    | sed 's/^{//g' \
    | sed 's/},$//g' \
    | awk -F",\"|\":" 'BEGIN{ OFS="\t" }
/phylum/ && NR>1 { 
   for(i=1;i<=NF;i++) 
      gsub(/"/,"",$i); print $2, $10, $8, $4, $18, $6, $12, $16, $14 }' \
    | sort | uniq

#!/bin/bash

#### mgrast_annot2pf.sh
##
## Convert a set of annotation files from MG-RAST API output to PathoLogic
## format
##
## TODO:
## * Allow the passing in of a list of defined bad contigs, or M5NR MD5
##   protein values, to exclude from the output
## 

input_dir="$1"
bad_contig_ids_file="$2"

if [ -e "$bad_contig_ids_file" ]
then

cat <<EOF > awk_prefilter.awk
BEGIN { 
   while((getline < "$bad_contig_ids_file")>0) {
         bad_contig[\$0]
         ##print > "/dev/stderr" 
   }
##  print "---" > "/dev/stderr"
} 
!/Download/ && !/query sequence/ { current_contig_id = gensub(/(.*)\|.*_([0-9]+)_.*/, "\\\2", "g", \$1)} ##; print current_contig_id > "/dev/stderr" }
##current_contig_id == "" { print > "/dev/stderr" }
!/Download/ && !/query sequence/ && !( current_contig_id in bad_contig ) && !annots[gensub(/(.*)\|.*_([0-9]+)_.*/, "\\\1_contig_\\\2", "g", \$1),\$2,\$13]++
EOF

else
    echo "baz"

cat <<EOF > awk_prefilter.awk
"!/Download/ && !/query sequence/ && !annots[gensub(/(.*)\|.*_([0-9]+)_.*/, "\\\1_contig_\\\2", "g", \$1),\$2,\$13]++
EOF

fi

sort -k 1,1 -k 2,2 $input_dir/*function_annots.tsv \
    | awk -F"\t" -f awk_prefilter.awk  \
    | awk -f <( cat <<EOF

BEGIN { FS = OFS = "\t" }

(NR%50)==0 { print "mgrast_annot2pf: Processed " NR lines" raw annotation lines." }

(current_contig = gensub(/(.*)\|.*_([0-9]*)_.*/, "\\\1_contig_\\\2", "g", \$1)) != previous_contig {
##print previous_contig, current_contig
if(NR>1) print "//" > contig_file_name

previous_contig = current_contig
##contig = current_contig
contig_file_name = current_contig ".pf"
##print contig_file_name

print "ID", "mg_rast_" gensub(/\./,"_","g",current_contig) > "genetic-elements.dat"
print "NAME", "Annotation file for MG-RAST contig " gensub(/\./,"_","g",current_contig) > "genetic-elements.dat"
print "CIRCULAR?", "N"  > "genetic-elements.dat"
print "ANNOT-FILE", contig_file_name  > "genetic-elements.dat"
print "//" > "genetic-elements.dat"

contig_changed = 1

}

\$2 != current_prot {
current_prot = \$2
##print current_prot
prot_changed = 1
}

prot_changed {
    
    if ( NR > 1 && !contig_changed)
      print "//" > contig_file_name

    contig_changed=0

    print "ID", "mg-rast_" ++max_id > contig_file_name
    print "PRODUCT-TYPE","P" > contig_file_name
    split(\$1,coverage,"[=\\\]]")
    print "ABUNDANCE", coverage[2] > contig_file_name
    print "DBLINK", "M5NR:" current_prot > contig_file_name
    print "FUNCTION-COMMENT", "Generated from MG-RAST API annotation output." > contig_file_name
    prot_changed = 0
    
}
 
{

  split(\$13,annots,";")
  for(annot_idx in annots) {
     ##if ( annots[annot_idx] != "hypothetical protein" )
        print "FUNCTION", annots[annot_idx] > contig_file_name
     if ( annots[annot_idx] ~ /EC[ :][0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ )
       print "EC", gensub(/.*[ :]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/,
                          "\\\1","g",annots[annot_idx]) > contig_file_name
  }
}
END { print "//" > contig_file_name }
EOF
)

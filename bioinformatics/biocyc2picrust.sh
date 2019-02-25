#!/bin/bash

#### biocyc2picrust.sh
##   Copyright (c) 2014, Tomer Altman
##   All rights reserved.
##   See bottom of script for full software license information.
## 
##
## Summary: Distill information in BioCyc collection into format that
## PICRUSt can parse.
##
## Example:
## ./biocyc2picrust.sh ~/biocyc/
##
## Description:
##
## PICRUSt can predict microbiome features from 16S rRNA survey data. 
## See the following paper for further description:
## http://www.ncbi.nlm.nih.gov/pubmed/23975157
##
## Until now PICRUSt has relied on the KEGG database for predicing
## pathways. The following script transforms data present in the BioCyc Collection
## flat-files in order to create input files that PICRUSt and STAMP can
## use for predicting compounds, reactions, and pathways from 16S data.
## 
## Why is this written in shell script, and not in Common Lisp using the
## Pathway Tools API? Well, switching between thousands of PGDBs is very
## slow. This code executes on a single beefy Linux server at Stanford in
## less than two minutes. Looping through so many PGDBs in Pathway Tools
## would take somewhere between half and hour and over an hour, depending
## on the machine.
##
##
## Arguments:
##
## It takes one argument, which is the base directory where all of the
##   PGDB sub-directores are located. This has been updated to expect
##   the directory structure of the v20.0 release of BioCyc.
##
## The script has a series of parameters that can be changed at the
## top of the file.
##
##
## Output:
##
## Four files, described below:
## 
## org_pwy_table:
## A tab-delimited file showing the association between PGDBs and MetaCyc
## pathway instances.
## The first row consists of column headers (i.e., MetaCyc pathway
## instance frame IDs). Each subsequent row represents a PGDB. Each row
## contains a row header consisting of the lower-case form of the PGDB's
## OrgID (i.e., 'ecoli' for EcoCyc). Each value for a given row and a
## given column represents whether that particular pathway instance is
## present in that particular PGDB. Presence is represented by '1', and
## absence is represented by '0'.
##
## org_rxn_table, org_cpd_table:
## The same format as org_pwy_table, but specifying presence/absence for
## those particular MetaCyc reactions or compounds.
##
## org_metadata_table:
## A tab-delimited file providing metadata about each PGDB included in the
## other three files. There are five columns, defined as follows:
## - NCBI Taxonomy Database identifier
## - BioCyc PGDB name 
## - Taxonomic name
## - Subspecies name
## - Strain name
##
##
## Side-effects:
##
## None.


### Parameters:

## Where to find the BioCyc Collection flat-files:
biocyc_collection_path="$1"

## Specific path to MetaCyc flat-files:
metacyc_path="$biocyc_collection_path/metacyc/"

[ "$TMPDIR" = "" ] && export TMPDIR=/tmp

## PGDB vs. pwy table:
org_pwy_table="$TMPDIR/biocyc_pwy_table.txt"

## PGDB vs. rxn table:
org_rxn_table="$TMPDIR/biocyc_rxn_table.txt"

## PGDB vs. cpd table:
org_cpd_table="$TMPDIR/biocyc_cpd_table.txt"

## PGDB metadata table:
org_metadata_table="$TMPDIR/pgdb_metadata.txt"



pushd $biocyc_collection_path > /dev/null


### Build organism metadata table first:

## errors: apie742159-hmpcyc, ecolicyc, shigellacyc
## Fix these two taxons manually ^^^

create_org_table () {

    ## Clear out of the way any pre-existing metadata file:
    rm -f /tmp/pgdb_metadata.txt


    ## Iterate over all PGDBs except for MetaCyc:
	
    for pgdb in `ls | grep cyc | egrep -v "biocyc-allcyc|metacyc"`
    do
	pushd $pgdb
	
	if [ -e default-version ]
	then
	    pgdb_version=`cat default-version`	
	    pushd $pgdb_version > /dev/null
	    ## If the organism-init.dat file is present, attempt to parse the NCBI Taxon ID out of it:
	    [ -e input/organism-init.dat ] && taxon=`gawk -F"\t" 'BEGIN{ RS="\r?\n"} /^NCBI-TAXON-ID/ { printf $2 }' input/organism-init.dat`
	    sep="\t"
	    input_file="input/organism.dat"
	elif [ -e species.dat ]	     
	then
	     taxon=`gawk -F" - " -v org_id="$pgdb" '$2 == toupper(org_id) { getline; split($2,tax_parts,"-"); print tax_parts[2]} species.dat`
	     sep=" - "
	     input_file="version.dat"
	fi
	
	## Gerate metadata table for PGDBs
	


	## Define a mapping file for PGDBs without NCBI Taxonomy IDs in
	## the organism-init.dat file:
	cat <<EOF > /tmp/biocyc2picrust_taxon_mapping.txt
AGRO	176299
ANO2	7165
ANTHRA	198094
ARA	3702
CAULO	190650
CPARVUM	414452
ECOLI	511145
ECOO157	155864
FRANT	177416
HPY	85962
HSP1118153	1118153
HUMAN	9606
MTBCDC	83331
MTBRV	83332
SHIGELLA	198215
VCHO	243277
YEAST	4932
EOF

	## Create a Gawk script for scraping out the desired metadata:

	
	## Execute the GAWK script:
	gawk -f <( cat <<'EOF'
        BEGIN { FS=OFS="\t"; RS="\r?\n" }
        NR == FNR { org_taxon[$1]=$2; next }
        /^ID/ { id=$2 }
        /^NAME/ { name=$2 }
        /^SUBSPECIES/ { subspecies=$2 }
        /^STRAIN/ { strain=$2 }
        END { if ( taxon == "" && id in org_taxon) taxon = org_taxon[id]
              print taxon, tolower(id), name, subspecies, strain }
EOF
		 ) \
	     -v taxon="$taxon" \
	     /tmp/biocyc2picrust_taxon_mapping.txt input/organism.dat \
	     >> $org_metadata_table

	popd > /dev/null
	
    done
    
}


## Create organism metadata file in the background:
## This is now obsolete, due to the BioCyc-Manifest.data file.
#create_org_table &


## Define the GAWK code for creating the organism vs. {pwy|rxn|cpd} tables:

cat <<EOF > /tmp/biocyc2picrust_instances.awk
BEGIN {

   FS=" - "
   while( ( getline < metacyc_instance_file ) > 0 ) ## command-line var
      if( /^UNIQUE-ID/ )
         metacyc_instances[\$2]

}

/^UNIQUE-ID/ {

   split(FILENAME,filename_path,"/")

   orgid=filename_path[1]

   ## Get rid of the trailing 'cyc':
   sub(/cyc\$/, "", orgid)

   orgs[orgid]

   org_instance[orgid,\$2]

}

END {

   ## print column headers
   for(inst in metacyc_instances)
      printf "\t%s", inst

   printf "\n"

   for( org in orgs ) {

      ## print row header
      printf "%s", org

      for( inst in metacyc_instances )
         printf "\t%s", ( ( (org, inst) in org_instance ) ? 1 : 0 )

      printf "\n"

   }

}
EOF

rm -f valid_pgdbs.txt
## Unfortunately, the following code is necessary to ferret out
## incomplete PGDBs:
for pgdb in `ls`
do
    [ -e $pgdb/pathways.dat ] \
	&& [ -e $pgdb/reactions.dat ] \
	&& [ -e $pgdb/compounds.dat ] \
	&& echo $pgdb \
		>> valid_pgdbs.txt
    
done

if [ -e $metacyc_path/data/pathways.dat ]
then
    metacyc_path="$metacyc_path/data"
fi

## Generate pathway table:
gawk -f /tmp/biocyc2picrust_instances.awk \
     -v metacyc_instance_file=$metacyc_path/pathways.dat \
     `awk '{ print $0 "/pathways.dat" }' valid_pgdbs.txt` \
     > $org_pwy_table &

## Generate reaction table:
gawk -f /tmp/biocyc2picrust_instances.awk \
     -v metacyc_instance_file=$metacyc_path/reactions.dat \
     `awk '{ print $0 "/reactions.dat" }' valid_pgdbs.txt` \
     > $org_rxn_table &

## Generate compound table:
gawk -f /tmp/biocyc2picrust_instances.awk \
     -v metacyc_instance_file=$metacyc_path/compounds.dat \
     `awk '{ print $0 "/compounds.dat" }' valid_pgdbs.txt` \
     > $org_cpd_table &


## This forces the parent script to block until all four background
## processes complete:
wait

popd > /dev/null

    
    # Copyright (c) 2014, Tomer Altman
    #  All rights reserved.
    # BSD 3 Clause license:
    # http://opensource.org/licenses/BSD-3-Clause
    # 
    # Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    # 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    # 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    # 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

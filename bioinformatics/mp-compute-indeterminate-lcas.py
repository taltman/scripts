#!/usr/bin/python

import fileinput
import sys
import csv
import gzip
import argparse

### Example:
##
## time ~/repos/public-scripts/bioinformatics/mp-compute-indeterminate-lcas.py \
##    $HOME/farmshare/third-party/bin/MetaPathways/v2.5.2 \
##    $PWD/oral_ch1_test/hybrid_assembly_dir/metapathways_v2-5/scaffolds \
##     | tee oral_ch1_test/hybrid_assembly_dir/metapathways_v2-5/scaffolds/results/annotation_table/fixed_indeterminate_ORFs.txt

### TODO:
## * Make exact name of refseq blast db file systematic, based on upstream specification by MP team.
## * Same for RefSeq.catalog.gz filename and location.

parser = argparse.ArgumentParser(description="Resolve MetaPathways 'indeterminate' taxonomy ORFs")

parser.add_argument('metapathways_path')
parser.add_argument('project_path')

args = parser.parse_args()

sys.path.append(args.metapathways_path + '/MetaPathways_Python.2.5.1/libs/python_modules/taxonomy')

import LCAComputation


project_path_parts = args.project_path.split('/')
project_name = project_path_parts[len(project_path_parts)-1]


taxonomy_file_base_dir = args.metapathways_path + '/MetaPathways_DBs/ncbi_tree'

## The current refseq catalog should be symlinked from the taxonomic directory:
refseq_catalog_file = args.metapathways_path + '/MetaPathways_DBs/taxonomic/RefSeq.catalog.gz'

annotation_file = args.project_path + '/results/annotation_table/functional_and_taxonomic_table.txt'

blast_file = args.project_path + '/blast_results/' + project_name + '.refseq-protein-v69.faa.BLASTout.parsed.txt'

tree_files = [ taxonomy_file_base_dir + "/ncbi_taxonomy_tree.txt"]

ncbi_tree = LCAComputation.LCAComputation(tree_files)

check_orfs = {}
gi_nums = {}
gi_num2orf = {}

## Step 1: Load in the annotation table:

annots = open(annotation_file, "r")

for line in annots:

    columns = line.split('\t')

    if columns[8] == 'indeterminate-taxonomy' or columns[8] == 'root (1)':
        check_orfs[columns[0]] = []

annots.close()


## Step 2: Load in the parsed blast results:

blast_parsed_file = open(blast_file, "r")

for line in blast_parsed_file:

    columns = line.split('\t')

    if columns[0] in check_orfs:
        target_seq_defline_parts = columns[1].split('|')
        gi_nums[target_seq_defline_parts[1]] = [ ]
        ## This ignores the many-to-many-mapping:
        gi_num2orf[target_seq_defline_parts[1]] = columns[0]
        check_orfs[columns[0]].append(target_seq_defline_parts[1])


blast_parsed_file.close()



## Get GI <-> TaxonID info from RefSeq catalog:

catalog_file = gzip.open(refseq_catalog_file)

for line in catalog_file:

    columns = line.split('\t')

    if columns[3] in gi_nums:
        gi_nums[columns[3]] = columns[0]

catalog_file.close()


## Review functional_and_taxonomic_table.txt:
    
annots = open(annotation_file, "r")

for line in annots:

    columns = line.split('\t')

    if columns[8] == 'indeterminate-taxonomy' or columns[8] == 'root (1)':
        taxa = [] 
        for gi_num in check_orfs[columns[0]]:
            taxa.append([gi_nums[gi_num]])
        taxonomy = ncbi_tree.getTaxonomy(taxa,False,True)
        if taxonomy != columns[8]:
            columns[8] = taxonomy

    ## Remove newline from last list element:
    columns[len(columns)-1] = columns[len(columns)-1].rstrip('\n')
    print '\t'.join(columns)
                        
annots.close()
    

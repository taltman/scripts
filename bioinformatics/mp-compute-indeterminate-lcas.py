#!/usr/bin/python

import fileinput
import sys
import csv
import gzip

sys.path.append('/afs/ir/users/t/a/taltman1/farmshare/third-party/bin/MetaPathways/v2.5.2/MetaPathways_Python.2.5.1/libs/python_modules/taxonomy')

import LCAComputation

taxonomy_file_base_dir = '/afs/ir/users/t/a/taltman1/farmshare/third-party/bin/MetaPathways/v2.5/MetaPathways_DBs/ncbi_tree'

refseq_catalog_file = '/afs/ir/users/t/a/taltman1/farmshare/bio_dbs/RefSeq/69/RefSeq-release69.catalog.gz'

annotation_file = '/afs/ir/users/t/a/taltman1/farmshare/single-cell-assembly-files/BoM_results/oral_ch1_test/hybrid_assembly_dir/metapathways_v2-5/scaffolds/results/annotation_table/functional_and_taxonomic_table.txt'

blast_file = '/afs/ir/users/t/a/taltman1/farmshare/single-cell-assembly-files/BoM_results/oral_ch1_test/hybrid_assembly_dir/metapathways_v2-5/scaffolds/blast_results/scaffolds.refseq-protein-v69.faa.BLASTout.parsed.txt'

tree_files = [ taxonomy_file_base_dir + "/ncbi_taxonomy_tree.txt"]

ncbi_tree = LCAComputation.LCAComputation(tree_files)

indeterminate_loci = {}
gi_nums = {}
gi_num2locus = {}

## Step 1: Load in the annotation table:

annots = open(annotation_file, "r")

for line in annots:
    ##annotation_file.input():

    columns = line.split('\t')

    if columns[8] == 'indeterminate-taxonomy':
        indeterminate_loci[columns[0]] = []
##        print columns[0] + ": indeterminate-taxonomy"

annots.close()

## Step 2: Load in the parsed blast results:

blast_parsed_file = open(blast_file, "r")

for line in blast_parsed_file:

    columns = line.split('\t')

    if columns[0] in indeterminate_loci:
        target_seq_defline_parts = columns[1].split('|')
        gi_nums[target_seq_defline_parts[1]] = [ ]
        ## This ignores the many-to-many-mapping:
        gi_num2locus[target_seq_defline_parts[1]] = columns[0]
        indeterminate_loci[columns[0]].append(target_seq_defline_parts[1])
##        print columns[0] + " " + target_seq_defline_parts[1]

blast_parsed_file.close()



## Start reading STDIN:

catalog_file = gzip.open(refseq_catalog_file)

for line in catalog_file:

    ## Here, get the contig and the contig lca value

    columns = line.split('\t')

    if columns[3] in gi_nums:
        gi_nums[columns[3]] = columns[0]
        print gi_num2locus[columns[3]] + " " + columns[3] + " " + columns[1] \
            + " " + columns[0]

catalog_file.close()

for locus in indeterminate_loci:

    print "Evaluating locus " + locus

    taxa = [] 
    for gi_num in indeterminate_loci[locus]:
        taxa.append([gi_nums[gi_num]])
        print "   " + gi_num + " " + ncbi_tree.getTaxonomy([[ gi_nums[gi_num] ]],False,True)
    taxonomy = ncbi_tree.getTaxonomy(taxa,False,True)

    print "   " + locus + " " + taxonomy
        
    ## What is the policy?
    ## TM7 taxon: we accept
    ## Root (1), organisms, bacteria (2), unclassified Bacteria
    ## all direct children of bacteria, and direct children of
    ## unclassified Bacteria (i.e., TM7's peer phyla)
    ##
    ## This needs to print out the name & TaxonID of filtered-out contigs,
    ## for error-checking.


###lca = str(columns[1]).rstrip('\n')

    # print line
    # print columns
    # print permitted_taxa
    # print ncbi_tree.get_lineage(lca)
    ## If the contig lca is on a short-list of permitted taxa, or is a TM7
    ## taxon, we approve and pass through:
   ## if permitted_taxa.count(lca) == 1 or \
     ##   ncbi_tree.get_lineage(lca).count('95818') == 1:
        ## 95818 is Candidatus Saccharibacteria

       # sys.stdout.write(line)

#    else:

 #       sys.stderr.write(line)
    
    

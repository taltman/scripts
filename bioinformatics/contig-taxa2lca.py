#!/usr/bin/python

## Take the output of mp-annots2contig-tax-ids.awk, and use MetaPathways'
## LCA code to compute the LCA for the contig.
##
## Example:
## time ~/repos/public-scripts/bioinformatics/contig-taxa2lca.py contig_taxa.txt 
import sys
import csv

sys.path.append('/afs/ir/users/t/a/taltman1/farmshare/third-party/bin/MetaPathways/v2.5.2/MetaPathways_Python.2.5.1/libs/python_modules/taxonomy')

import LCAComputation


## Parameters:

taxonomy_file_base_dir = '/afs/ir/users/t/a/taltman1/farmshare/third-party/bin/MetaPathways/v2.5/MetaPathways_DBs/ncbi_tree'

input_file = sys.argv[1]


contig_taxa = list(csv.reader(open(input_file,'rb'),
                              delimiter = '\t'))

tree_files = [ taxonomy_file_base_dir + "/ncbi_taxonomy_tree.txt"]

ncbi_tree = LCAComputation.LCAComputation(tree_files)

## ncbi_tree.get_lca([1,2,3],return_id=True)

for contig in contig_taxa:
    print contig[0] + "\t" + str(ncbi_tree.get_lca(contig[1:],return_id=True))

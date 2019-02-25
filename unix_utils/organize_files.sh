#!/bin/bash

#### organize_files.sh
##
## Description:
##
## This script helps bring a big pile of files into order.
## First, all files are grouped by year and month, the rationale being that all files related to some activity in time would then be in the same folder, and thus easier to sort through.

source_dir="$1"

curr_year="`date '+%Y'`"

pushd $source_dir > /dev/null

ls -lh | awk -v curr_year="$curr_year" \
	     '$9 !~ /20[0-9][0-9]-[A-Z][a-z][a-z]/ { curr_dir=(($8 ~ /:/)?(curr_year "-" $6):($8 "-" $6)); \
                                                     system("mkdir -p "curr_dir "; mv \"" substr($0,match($0,$9)) "\" " curr_dir "/")}'

# do					      

#     mkdir -p entry

# done

# ls -lh \
#     | awk 
# { 
  
# system("mv " $9 "  }'`


    
    




popd > /dev/null

#!/bin/bash

### shuffle_prot_db.sh

## Given a protein database, shuffle the order.

input_db="$1"
sample_size="$2"

if [ "$sample_size" ]; then

tr '\n' '|' < $input_db | \
    sed 's/|>/\n>/g' | \
    sed 's/|$/\n/g' | \
    shuf | \
    head -n $sample_size | \
    tr '|' '\n'

else

tr '\n' '|' < $input_db | \
    sed 's/|>/\n>/g' | \
    sed 's/|$/\n/g' | \
    shuf | \
    tr '|' '\n'

fi
#!/bin/bash

## For example, SwissProt has 540261 protein sequences, and the blastx results had 711147 distinct complete read results, so the total possible
## pairs would be: 711147 * 540261 = 384204989367
#COMPARE_SPACE="$1"
set_1="$1"
set_2="$2"

intersection_size=`comm -12 $set_1 $set_2 | wc -l`
two_not_one_size=`comm -13 $set_1 $set_2 | wc -l`
one_not_two_size=`comm -23 $set_1 $set_2 | wc -l`
union_size=`awk "BEGIN{ print $intersection_size + $two_not_one_size + $one_not_two_size }"`

jaccard_index=`awk "BEGIN{ print $intersection_size / $union_size }"`

echo "Intersection size: $intersection_size"
echo "One not two size: $one_not_two_size"
echo "Two not one size: $two_not_one_size"
echo "Union size: $union_size"
echo "Jaccard index: $jaccard_index"
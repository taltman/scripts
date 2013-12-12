#!/bin/bash

## For example, SwissProt has 540261 protein sequences, and the blastx results had 711147 distinct complete read results, so the total possible
## pairs would be: 711147 * 540261 = 384204989367
COMPARE_SPACE="$1"
TRUTH_FILE="$2"
PREDICTION_FILE="$3"

true_positives=`comm -12 $TRUTH_FILE $PREDICTION_FILE | wc -l`
false_positives=`comm -13 $TRUTH_FILE $PREDICTION_FILE | wc -l`
false_negatives=`comm -23 $TRUTH_FILE $PREDICTION_FILE | wc -l`
true_negatives=`awk "BEGIN{ print $COMPARE_SPACE - $true_positives - $false_positives - $false_negatives }"`

accuracy=`awk "BEGIN{ print ( $true_positives + $true_negatives )/ $COMPARE_SPACE }"`
error_rate=`awk "BEGIN{ print 1 - $accuracy }"`
sensitivity=`awk "BEGIN{ print $true_positives / ($true_positives + $false_negatives) }"`
specificity=`awk "BEGIN{ print $true_negatives / ($true_negatives + $false_positives) }"`

echo "True positives: $true_positives"
echo "False positives: $false_positives"
echo "False negatives: $false_negatives"
echo "True negatives: $true_negatives"
echo "---"
echo "Accuracy: $accuracy"
echo "Error rate: $error_rate"
echo "Sensitivity: $sensitivity"
echo "Specificity: $specificity"
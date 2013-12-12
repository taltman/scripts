#!/usr/bin/gawk -f

### confusion_matrix.awk
##
## Use the output of unix util comm.awk to construct a confusion matrix, along with associated measurements
## (accuracy, FPR, etc.)
##
## The heavy lifting is done by comm.awk. Here we parse the stderr
## output of comm.awk, cast the values in the terminology of
## classifier evaluation, and produce output for the user:
##
## Example usage:
## time comm.awk predicted.txt gold_standard.txt 2>&1 > /dev/null | confusion_matrix.awk
##
## Here we assume that both the predicted.txt and gold_standard.txt
## are tab-delimited files with two columns each. The first column
## is an object identifier, and the second column is a class.
##
## Alternate mode:
## 
## The traditional classification task of predicting
## 'positive' or 'negative' for a set of objects, in which case we know
## the size of objects under consideration. For classification tasks
## where not every possible object gets classified, we have to do
## different types of calculations to provide a meaningful
## analysis. As a concrete example, you can have a classifier that
## takes a list of queries, and tries to match them to documents. The
## complication is that it returns zero or more documents per
## query. That means that every true negative is not present in the
## predicted.txt file, to use the above example command line.
##
## A simple solution is to provide a command-line AWK variable that
## represents the total number possible pairings between queries and
## documents.
##
## In the below example, we assume that each line of predicted.txt and
## gold_standard.txt represents a matching between ten queries and ten
## documents, to use the example from above. 
##
## Example usage:
## time comm.awk predicted.txt gold_standard.txt 2>&1 > /dev/null | \
## confusion_matrix.awk -v total=100


BEGIN { FS=OFS="\t" }

$1 == "Number of unique lines in File 1 but not in File 2:" { false_positives = $2 }
$1 == "Number of unique lines in File 2 but not in File 1:" { false_negatives = $2 }
$1 == "Distinct common lines:" { true_positives = $2 }
$1 == "File 1 number of lines" { num_objects = $2 }

END {

    if ( total )
	num_objects = total

    true_negatives = num_objects 

}

Set 1
A:T
B:F
C:T

Set 2
A:F
B:F
C:T

Intersection:

B:F

Set1not2
A:T
C:T

Set2not1
A:F
C:F



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


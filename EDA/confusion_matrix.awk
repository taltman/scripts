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
## time comm.awk predicted.txt gold_standard.txt 2> /dev/null | confusion_matrix.awk
##
## Here we assume that both the predicted.txt and gold_standard.txt
## are tab-delimited files with two columns each. The first column
## is an object identifier, and the second column is a class.
##
## In the current iteration of this script, We only support a
## two-class classifier, where they have class labels of "T" and
## "F" (i.e., true and false). These class labels should be put in the
## file on the same line as the object label, with a separator
## character inbetween. The character can be specified on the command
## line as follows:
## -v class_sep_opt='|'
## 
##
### Arguments:
## * class_sep_opt (optional)
##   Character that separates identifier from classification.
##   Defaults to ":".

## TODO:
##
## * Expand script to be able to handle multi-class classifiers.

BEGIN { 

    FS=OFS="\t" 

    class_sep = (class_sep_opt) ? class_sep_opt : ":"

}

$1 ~ (class_sep "F") { false_negatives++ }
$1 ~ (class_sep "T") { false_positives++ }
$3 ~ (class_sep "F") { true_negatives++ }
$3 ~ (class_sep "T") { true_positives++ }

END {

    num_correct = true_positives + true_negatives
    num_incorrect = false_positives + false_negatives
    num_true = true_positives + false_negatives
    num_false = true_negatives + false_positives
    num_positive = true_positives + false_positives
    num_negative = true_negatives + false_negatives
    total = num_true + num_false

    print "* Basic Statistics:"
    print ""
    print "Total objects:", total
    print "True positives:", true_positives
    print "True negatives:", true_negatives
    print "False positives:", false_positives
    print "False negatives:", false_negatives
    print ""

    print "* Table view:"

    printf "\t\tPredicted\n"
    printf "\t\tPositive\tNegative\tTotal\n"
    printf "Truth\tTrue\t%d\t%d\t%d\n", true_positives, false_negatives, num_true
    printf "\tFalse\t%d\t%d\t%d\n", false_positives, true_negatives, num_false
    printf "\tTotal\t%d\t%d\t%d\n", num_positive, num_negative, total
    
    print ""
    print "* Prediction Metrics:"
    print ""
    print "Accuracy:", num_correct"/"total, num_correct*100/total"%"
    print "Error Rate:", num_incorrect "/" total, num_incorrect*100/total"%"
    print "Sensitivity (Recall):", true_positives "/" num_true, true_positives*100/num_true"%"
    print "Specificity (TNR):", true_negatives "/" num_negative, true_negatives*100/num_negative"%"
    print "Precision:", true_positives "/" num_positive , true_positives*100 / num_positive"%"
    print "False Positive Rate:", false_positives "/" num_false, false_positives*100/num_false"%"
    print "False Negative Rate:", false_negatives "/" num_true, false_negatives*100/num_true"%"

    ## Need to add precision, recall, F-measure, sensitivity, and specificity
}

# Set 1
# A:T
# B:F
# C:T

# Set 2
# A:F
# B:F
# C:T

# Intersection:

# B:F

# Set1not2
# A:T
# C:T

# Set2not1
# A:F
# C:F


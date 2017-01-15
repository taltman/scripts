#!/usr/bin/gawk -f

## Transpose a text-delimited data file.
## (rows become columns, and columns become rows)

## Example:

## transpose.awk -v FS=":" -v outFS=":" /etc/passwd

## To change the field separator, call as:
## transpose.awk -v FS="\t"
## (default is whitespace, like awk)

## To modify the output delimiter:
## transpose.awk -v outFS=":"
## Default is tab-delimited output.

BEGIN { (outFS!="") ? OFS=outFS : OFS="\t" }

{ 

    for(i=1; i<=NF; i++) 
	table[i,NR]=$i 

}

END { 

    for(i=1;i<=NF;i++) {
	for(j=1; j<=NR; j++) 
	    printf (table[i,j] ((j==NR)?"":OFS))
	print ""
    }
}

#!/usr/bin/awk -f 

## Example usage:
## picrust2pf.awk -v database_name="HOT_100m" HOT_100m_picrust_output.txt

## Output goes to sub-directories.
## One sub-directory for each sample.
## An extra sub-directory for the union of all samples.

## Copyright Tomer Altman
## BSD License

function printGeneticElementsRecord(output_file, sample_name) {

    print "ID", "picrust_chrom_" sample_name >> output_file
    print "NAME", "PICRUSt chromosome for sample " sample_name   >> output_file
    print "CIRCULAR?", "N"                   >> output_file
    print "ANNOT-FILE", sample_name ".pf"    >> output_file		
    print "//"                               >> output_file		

}



function printPfRecord(output_file, 
		       sample_name, 
		       function_id, 
		       function_description, 
		       abundance) {

    if ( abundance > 0.0 ) {
	print "ID", sample_name "_" (NR - 2)                     >> output_file
	print "NAME", "gene_" function_id                        >> output_file		
	print "PRODUCT-TYPE", "P"                                >> output_file		
	##print function_description ~ /\[EC\:/ 
	if ( function_description ~ /\[EC\:/ ) {
	    split(function_description,ec_part,"EC\:")
	    ##print ec_part[2]
	    split(ec_part[2],ec_nums,"[ \\]]")
	    for (num in ec_nums)
		##print num, ec_nums[num]
		if ( ec_nums[num] !~ /-/ && ec_nums[num] != "" )
		    print "EC", ec_nums[num]                     >> output_file
	}
	print "FUNCTION", function_description                   >> output_file
	print "FUNCTION-COMMENT", "Derived from PICRUSt output." >> output_file
	print "DBLINK", database_name ":" function_id            >> output_file
	print "ABUNDANCE", abundance                             >> output_file
	print "//"                                               >> output_file		
    }
}



## Argument: 
BEGIN { 

    FS=OFS="\t" 
    
    if(database_name == "") {
	print "database_name argument required! Exiting"
	exit
    }

}

## Remember, samples[1] == "#OTU ID", so skip
$1 == "#OTU ID" { 

    system("mkdir -p all_picrust_ptools")

    for(i=2; i < NF; i++) {
	samples[i] = $i
	system("mkdir -p " samples[i] "_ptools")

	## Print entry for per-sample genetic-elements.dat:
	printGeneticElementsRecord(samples[i] "_ptools/genetic-elements.dat",
				   samples[i])
    }	

    ## Print entry for all_picrust summary:
    printGeneticElementsRecord("all_picrust_ptools/genetic-elements.dat",
			       "all_picrust")

    next
}

NR > 2 { 

    row_sum = 0;
    for (i=2; i< NF; i++) {
	
	## set the output file:
	printPfRecord(samples[i] "_ptools/" samples[i] ".pf",
		      samples[i],
		      $1,
		      $NF,
		      $i)
	
	row_sum+=$i    
    }

    ## Print the average abundance to the all_picrust.pf file:
    printPfRecord("all_picrust_ptools/all_picrust.pf",
		  "all_picrust",
		  $1,
		  $NF,
		  row_sum/(NF-2))

}

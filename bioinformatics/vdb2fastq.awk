### vdb2fastq.awk
##
## Copyright held by Tomer Altman, 2021
##
## This script is motivated by the desire to extract a select number of reads from an SRA file
## in FASTQ format. You can use vdb-dump for this purpose, but it concatenates the DNA and QUAL
## character sequences of the forward and reverse read ends. Using fastq-dump and then filtering
## out what you want is too slow.
##
## This uses the row & column selector arguments of vdb-dump to choose which reads we want,
## and then reformat them as FASTQ. You can provide an argument of `-v offset=64` if you don't
## want to use the default ASCII character offset of 33 for mapping from Phred scores. If you
## omit the `-v run=SRR12345` argument, a place-holder name of "run" is used.
##
## Example usage:            
##
## time vdb-dump -C NAME,READ,QUALITY,READ_START -R 783055,14629536,7417843 SRR6937774 \
##     | awk -f vdb-dump2fastq.awk -v run=SRR6937774
##            
## # Assuming a pre-fetched SRA file, it runs in less than a second
##
## The above will generate two FASTQ-formatted files: SRR6937774_1.fastq, and SRR6937774_2.fastq,
## with Phred+33 ASCII quality score encoding.

BEGIN {
    FS = ": "
    if(!offset)
        offset = 33
    if(!run)
        run = "run"
}

$1 ~ /NAME$/ { name = $2; next }

$1 ~ /QUALITY$/ {

    num_quals = split($2,quals,", ")
    ascii_qual = ""
    for(i=1; i<=num_quals; i++)
        ascii_qual = ascii_qual sprintf("%c",quals[i]+offset)
    next
}

$1 ~ /READ$/ { seq = $2; next }

$1 ~ /READ_START$/ {
    split($2,starts,", ")

    for(i=1; i<=2; i++) {
        output_file = run "_" i ".fastq"
        print "@" run "." name "." i                   > output_file
        print substr(seq,starts[i]+1,starts[2])        > output_file
        print "+" run "." name "." i                   > output_file
        print substr(ascii_qual,starts[i]+1,starts[2]) > output_file
    }

}

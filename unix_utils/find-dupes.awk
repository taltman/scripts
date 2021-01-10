### find-dupes.awk
##
## Copyright held by Tomer Altman, 2021
##
## Inspired by the discussion here:
## https://unix.stackexchange.com/questions/277697/
## 
## Call with output from 'ls -lTR' as follows:
## `ls -lTR | time awk -f ~/repos/bin/find-dupes.awk > hash-dupes.txt`
## 
## This has been tested on a FreeBSD system. It should work with gawk
## without much modification, as it was written to use only POSIX
## features. Possibly GNU ls might have slight output formatting
## differences that might break processing.
##
## What will need to be modified to work on a GNU shell:
## * Switch md5_exec to use "md5sum"
## * The parsing of the md5sum output will need be modified, as it is
##   different than md5 on FreeBSD
##
## Performance anecdote:
##
## On a deeply nested directory with >380 GB of JPG and MOV files,
## this identified 147 duplicates in 72 seconds. Using the `find -exec
## md5sum` approach from the unix.stackexchange.com link above, on the
## other hand, took 97 minutes.


BEGIN{
    OFS = "\t"
    md5_exec = "md5"
    ## md5_exec = "md5sum"
}

/:$/ {
    sub(/:$/, "")
    dir = $0
    next
}

## Parse ls -lTR output:                                              
NF && !/^total/ {
    gsub(/\*$/,"")
    file = substr($0,match($0, $9)+length($9)+1,length($0))
    file_size[$5, ++file_size[$5,"length"]] = dir "/" file
    if(file_size[$5, "length"] > 1 && $5 > 35)
        sizes[$5]
}

END {
    ## Find the files that have identical sizes, and then get their MD5 hash:
    for(size in sizes)
        for(i=1; i<=file_size[size,"length"]; i++) {
            file = file_size[size,i]
                FS=" = "
                #print "'" file "'"
                (md5_exec " '" file "'") | getline
                    hash = $2
                    file_hash[hash,++file_hash[hash,"length"]] = file
                    if (file_hash[hash,"length"]>1)
                        hashes[hash]
        }

## Report files that have identical MD5 hashes:                  
    for(hash in hashes) {
        print hash
        for(i=1; i<=file_hash[hash,"length"]; i++)
            print OFS file_hash[hash,i]
    }
}

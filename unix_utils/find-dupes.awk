# Call with output from 'ls -lTR'   
# ls -lTR | time awk -f ~/repos/bin/find-dupes.awk > hash-dupes.txt

BEGIN{
    OFS = "\t"
    
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
                ("md5 '" file "'") | getline
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

#!/bin/bash

### shorten-filenames.sh
##
## by Tomer Altman <taltman at gmail dot com>
##
## Copyright 2013 Tomer Altman
##
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## Example: 
##
## shorten-filenames.sh ~/tmp/shorten-name-test encode 100
##
## Syntax:
##
## shorten-filenames.sh [[[<directory>] <operation>] <filename-length-threshold> ]
##
##
## Description:
##
## This script, performing the 'encode' <operation>, will search a
## directory root at <directory> for filenames (files and directories)
## that have a name length greater than or equal to
## <filename-length-threshold>. Any such names are recorded in a dot
## file in the same directory in which it is found, along with a SHA1
## summary of the namestring. Finally, the file or directory is renamed
## to the SHA1 summary of the namestring. 
##
## When performing the 'decode' <operation>, the actions taken by the
## 'encode' <operation> are reversed, such that the root directory
## <directory> is as it was before the 'encode' <operation (except for
## file timestamps, which will have been modified). 
##
## The motivation for this script was the need to circumvent a
## limitation with filesystems where names cannot be longer than 255
## characters. If you are encrypting a directory using encsfs, the name
## encryption string makes the file or directory names longer than
## usual, which can often push it over the 255 limit. Thus, by applying
## the SHA1 summary of the name string, we can shorten the name string
## length, and avoid the problem in using encfs. 
##
## See the following for more context:
##
## * http://stackoverflow.com/questions/8239227/is-there-a-workaround-for-the-filename-length-limit-in-encfs
## * http://rdiff-backup.stanford.edu/rdiff-backup.1.html#sect10
## * https://bugs.launchpad.net/ubuntu/+source/rsync/+bug/853243
## 
## Help & Feedback
##
## I want to make this script as good as it can be. Please feel free to fork or to send me feedback!


### Make these take on defaults:
directory="${1:-$PWD}"
direction="${2:-encode}"
cutoff="${3:-190}"

### Parameters:

## The non-dot part of the hidden dot file name:
file_metadata_name="shorten-filenames"

## The hash/summary function to use. On my MacOSX, shasum was available:
hash_function="shasum"


### Functions:

## Test whether the specified hash returns a name longer than script argument specification:
    
[ `echo "foo" | $hash_function | awk '{print length($1)}'` > cutoff ] && \
    { echo "shorten-filenames.sh: Hash function $hash_function returns string longer than the specified cutoff."; }
    



## For 'find' to work, we need to have extended POSIX regular expressions.
## Different UNIXes do this differently:
if [ "`uname`" == "Linux" ]; then
    find_option=""
    find_execution_option="-regextype posix-extended "
else ## This is for BSD-like, such as Darwin OS:
    find_option="-E "
    find_execution_option=""
fi

## Dispatch based on whether we are "encoding" or "decoding":

if [ "$direction" == "encode" ]; then

## Iterate over a list of files with names longer than cutoff:

    for full_path in `find $find_option $directory $find_execution_option -regex ".*/.{$cutoff,}$" -print`
    do
	
	curr_dir=`dirname $full_path`
	filename=`basename $full_path`
	
	pushd $curr_dir	> /dev/null

	## Test to see if this directory has already been encoded. 
	## This code does not support a mode of operation where you can encode
	## a directory multiple times.
	[ -e .$file_metadata_name ] &&  (echo "shorten-filenames.sh: it appears that directory $curr_dir has already been shortened. Aborting." && exit 1)
       
	## Generate the hash/summary of the filename:
	filename_sha1=`echo $filename | $hash_function | cut -d' ' -f 1`    
	
	## Stash away the original name, and the hash/summary key, in the hidden file:
	printf "%s\t%s\n" $filename $filename_sha1 >> $curr_dir/.$file_metadata_name
	
	## Finally, rename the file/directory:
	mv $filename $filename_sha1
	
	popd > /dev/null

    done

else

    ## Iterate over all directories that contain a hidden file for stashing long names:
    for full_path in `find $directory -name ".$file_metadata_name"`
    do

	curr_dir=`dirname $full_path`
	
	pushd $curr_dir > /dev/null
	
	## Use awk to process the tab-delimited file, restoring the original names:
	awk -F'\t' '{ system("mv "$2" "$1) }' .$file_metadata_name

	## If awk succeeded, nuke the hidden file:
	[ "$?" -eq 0 ] && rm -f .$file_metadata_name

	popd > /dev/null

    done

fi

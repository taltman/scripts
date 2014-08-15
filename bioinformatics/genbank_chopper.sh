#!/bin/bash

#### genbank_chopper.sh
##
##   Split a multi-contig GenBank-formatted annotation (and 
##   possibly also sequence) file into a set of 
##   per-contig GenBank-formatted files. Also, generate the 
##   genetic-elements.dat index file for the set of files, as
##   needed as input for PathoLogic.
##
## Inspired by data processing of a sponge draft genome for Cara Fiore,
## WHOI, at STAMPS, MBL, 2014

### License: 
##
##   Copyright (c) 2014, Tomer Altman
##   All rights reserved.
##   See bottom of script for full software license information.

### Synopsys:
##
## genbank_chopper.sh [file prefix] [path to GenBank annotation file] [decimal places]

### Example:
##
## genbank_chopper.sh E-coli-K12-MG1655- e_coli_k12_acc_num_12345.gbk 5

### Arguments
##
## file prefix:
## A common prefix for all of the generated files. It needs to only 
## include alphanumeric characters or hyphens.
##
## path to GenBank annotation file:
## Filesystem path to the multi-contig GenBank-formatted annotation
## (and possibly sequence ) file.
##
## decimal places:
## An integer representing how many decimal places should be used for 
## the incrementing portion of the output GenBank-formatted file names.

### Output:
##
## A set of GenBank-formatted files, one per contig in the input 
## GenBank-formatted file. Also, a Pathway Tools PathoLogic 
## genetic-elements.dat file will be generated.
##
## An example of an output GenBank-formatted file name:
## E-coli-K12-MG1655-00001.gbk
##
## An example genetic-elements.dat file can be found here:
## http://bioinformatics.ai.sri.com/ptools/sample-genetic-elements.dat

prefix="$1"
file="$2"
decimal_places="$3"

time csplit -f $prefix -n $decimal_places -b "%0${decimal_places}d.gbk" -z "$file" /^\/\//+1 {*}

ls *.gbk | awk -F'.gbk' '{
print "ID\t" $1
print "NAME\t" $1
print "TYPE\t:CONTIG"
print "CIRCULAR?\tN"
print "ANNOT-FILE\t" $0
print "//"}' > genetic-elements.dat



    # Copyright (c) 2014, Tomer Altman
    #  All rights reserved.
    # BSD 3 Clause license:
    # http://opensource.org/licenses/BSD-3-Clause
    # 
    # Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    # 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    # 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    # 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

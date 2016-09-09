#!/bin/bash

#### split-tar-by-dir.sh
##
## Description:
## Given a tar ball, create a set of smaller tar balls, where each tar
## ball is a top-level directory that was present in the given tar
## ball.

tarball="$1"

tmpdir="`mktemp -d split-tar-by-dir.XXX`"

echo "Temp dir: $tmpdir"

curr_dir="$PWD"

pushd $tmpdir > /dev/null

##gunzip $tarball > tarball.tar

ln -s $curr_dir/$tarball tarball.tar

base_name="`basename $tarball .tar.gz`"

mkdir new-tar-ball-dir

pushd new-tar-ball-dir

for tardir in `tar tf tarball.tar | head | egrep "\/$"`
do

    new_tar_ball_name="`basename $tardir`"
    echo "Extracting $tardir"
    tar xf ../tarball.tar $tardir 

    echo "Re-archiving $tardir:"
    tar czf \
	$new_tar_ball_name.tgz \
	$tardir
    
done

popd


popd > /dev/null

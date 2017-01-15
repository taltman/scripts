#!/bin/bash

#### split-tar-by-dir.sh
##
## Description:
## Given a tar ball, create a set of smaller tar balls, where each tar
## ball is a top-level directory that was present in the given tar
## ball.

tarball="$1"

tmpdir="`mktemp -d /tmp/split-tar-by-dir.XXX`"

pushd tmpdir > /dev/null

gunzip $tarball > tarball.tar

base_name="`basename $tarball .tar.gz`"

mkdir new-tar-ball-dir





popdir > /dev/null

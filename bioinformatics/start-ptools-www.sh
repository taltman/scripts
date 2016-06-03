#!/bin/bash

## Adapted from:
## bioinformatics.ai.sri.com/ptools/web-logout.html

org_list="ecoli+meta"
## Make sure something isn't already using our port:

if [[ "1" == "`netstat -a | egrep -c '1555.*LISTEN'`" ]]; then

    echo "Something is already listening on port 1555"
    echo "Please stop whatever it is, and then try $0 again."
    exit 1

fi

## Set up the virtual frame buffer:
## Pick some ridiculously high display value, such as 1555:

Xvfb -nolisten tcp :1555 2>&1 >> $HOME/logs/ptools-xvfb.log &
## || \
##    { echo "$0 error: Xvfb invocation failed."; exit 2; }

pushd $HOME/farmshare/third-party/bin/pathway-tools 

DISPLAY=":1555" ./pathway-tools -www -www-publish "$org_list" || \
    { echo "$0 error: pathway-tools invocation failed."; exit 3; }
 
popd

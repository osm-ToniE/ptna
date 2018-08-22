#!/bin/bash

#
# analyze ÖPNV networks via cronjob
#

PATH=$PWD/bin:$PATH

analyze-all-networks.sh -oau > analyze-all-networks.log 2>&1 < /dev/null

emptyxml=$(ls Networks/*/*.xml | fgrep -c " 0 $(date '+%b %d') ")

if [ "$emptyxml" -lt 10 ]
then
    # most of the analysis succeeded, let's try a second time for the others
    
    sleep 300
    
    analyze-all-networks.sh -Oau >> analyze-all-networks.log 2>&1 < /dev/null
fi

if [ -n "$TARGET_HOST" -a -n "$TARGET_LOC" ]
then
    echo -e "put analyze-all-networks.log $TARGET_LOC/\nchmod 644 $TARGET_LOC/analyze-all-networks.log" | sftp -b - $TARGET_HOST
fi



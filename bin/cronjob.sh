#!/bin/bash

#
# analyze ÖPNV networks via cronjob
#
export LANG=C

PATH=$PWD/bin:$PATH

LOGFILE=analyze-all-networks.txt

analyze-all-networks.sh -oau > $LOGFILE 2>&1 < /dev/null

emptyxml=$(ls -l Networks/*/*.xml | fgrep -c " 0 $(date '+%b %d') ")

if [ "$emptyxml" -gt 0 -a "$emptyxml" -lt 10 ]
then
    # most of the analysis succeeded, let's try a second time for the others
    
    sleep 300
    
    analyze-all-networks.sh -Oau >> $LOGFILE 2>&1 < /dev/null
fi

if [ -n "$TARGET_HOST" -a -n "$TARGET_LOC" ]
then
    echo -e "put $LOGFILE $TARGET_LOC/\nchmod 644 $TARGET_LOC/$LOGFILE" | sftp -b - $TARGET_HOST
fi



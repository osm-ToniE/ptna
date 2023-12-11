#!/bin/bash

#
# analyze ÖPNV networks
#

# 6 jobs in parallel
XARG="P6"

cd $PTNA_NETWORKS_LOC

if [ -z "$PTNA_OVERPASS_API_SERVER" ]
then
    if [ $(echo $* | fgrep -c -i o) -gt 0 ]
    then
        # 1 job at a time only if option 'o' = 'overpass' or 'O' = 'overpass on empty XML' is set
        XARG="P1"
    fi
fi
if [ $(echo $* | fgrep -c L) -gt 0 ]
then
    # overwrite existing logfile, deleting the old information
    find . -name settings.sh | \
    sort                     | \
    xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B - options: '$*' && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'
else
    # append log info to existing logfile
    find . -name settings.sh | \
    sort                     | \
    xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B - options: '$*' && cd $D && ptna-network.sh '$*' >> $PTNA_WORK_LOC/log/$B.log 2>&1'
fi

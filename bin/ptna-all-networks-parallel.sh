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

find . -name settings.sh | \
sort                     | \
xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B && cd $D && ptna-network.sh '$*' >> $PTNA_WORK_LOC/log/$B.log 2>&1'

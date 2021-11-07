#!/bin/bash

#
# analyze ÖPNV networks
#

cd $PTNA_NETWORKS_LOC

if [ -z "$PTNA_OVERPASS_API_SERVER" ]
then
    # 1 job at a time only
    XARG="P1"
else
    # 6 jobs in parallel
    XARG="P6"
fi

find . -name settings.sh | \
sort                     | \
xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'

#!/bin/bash

#
# analyze ÖPNV networks
#

cd $PTNA_NETWORKS_LOC

if [ -n "$PTNA_OVERPASS_API_SERVER"]
then
    # 6 jobs in parallel
    XARG="P6"
else
    # 1 job at a time only
    XARG="P1"
fi

find . -name settings.sh | \
sort                     | \
xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'

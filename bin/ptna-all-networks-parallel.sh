#!/bin/bash

#
# analyze ÖPNV networks
#

# 6 jobs in parallel
XARG="P6"

if [ -z "$PTNA_OVERPASS_API_SERVER" ]
then
    if [ $(echo $* | fgrep -c -i o) -gt 0 ]
    then
        # 1 job at a time only if option 'o' = 'overpass' or 'O' = 'overpass on empty XML' is set
        XARG="P1"
    fi
fi

if [ $(echo $* | fgrep -c e) -gt 0 ]
then
    # use "e"xtracts from planet dumps if configured, otherwise 'ptna-network.sh' will fall-back to Overpass-API ("o")
    # download, update and split relevant planet extracts before analyzing the data
    cd $PTNA_WORK_LOC

    ptna-handle-extracts.sh $PTNA_NETWORKS_LOC
fi

cd $PTNA_NETWORKS_LOC

if [ $(echo $* | fgrep -c L) -gt 0 ]
then
    # overwrite existing logfile, deleting the old information
    find . -name settings.sh | \
    sort                     | \
    xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S %Z") $B - options: '$*' && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'
else
    # append log info to existing logfile
    find . -name settings.sh | \
    sort                     | \
    xargs -$XARG -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S %Z") $B - options: '$*' && cd $D && ptna-network.sh '$*' >> $PTNA_WORK_LOC/log/$B.log 2>&1'
fi

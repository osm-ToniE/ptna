#!/bin/bash

#
# analyze ÖPNV networks
#

# 6 jobs in parallel
XARG="P6"

if [ -z "$PTNA_OVERPASS_API_SERVER" ]
then
    if [ $(echo $* | grep -F -c -i o) -gt 0 ]
    then
        # 1 job at a time only if option 'o' = 'overpass' or 'O' = 'overpass on empty XML' is set
        XARG="P1"
    fi
fi

if [ $(echo $* | grep -F -c e) -gt 0 ]
then
    # use "e"xtracts from planet dumps if configured, otherwise 'ptna-network.sh' will fall-back to Overpass-API ("o")
    # download, update and split relevant planet extracts before analyzing the data
    cd $PTNA_WORK_LOC

    ptna-handle-extracts.sh $PTNA_NETWORKS_LOC
fi

cd $PTNA_NETWORKS_LOC

find . -name settings.sh | \
sort                     | \
xargs -$XARG -I@ bash -c 'D=$(dirname @) && cd $D && echo $(date "+%Y-%m-%d %H:%M:%S %Z") $(basename $PWD) - options: '$*' && ptna-network.sh '$*''

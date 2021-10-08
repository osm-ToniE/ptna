#!/bin/bash

#
# analyze ÖPNV networks
#


cd $PTNA_NETWORKS_LOC

WD=$PWD

for S in $(find . -name settings.sh | sort)
do
    D=$(dirname $S)
    if [ -d $D ]
    then
        echo
        echo $(date "+%Y-%m-%d %H:%M:%S") "$D"
        echo

        cd $D

        B=$(basename $D)

        ptna-network.sh $* > $PTNA_WORK_LOC/log/$B.log 2>&1

        cd $WD
    fi

done

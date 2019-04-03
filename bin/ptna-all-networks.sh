#!/bin/bash

#
# analyze ÖPNV networks
#


cd $PTNA_NETWORKS_LOC

WD=$PWD

for S in $(find . -name settings.sh)
do
    D=$(dirname $S)
    if [ -d $D ]
    then
        echo
        echo $(date "+%Y-%m-%d %H:%M:%S") "$D"
        echo
    
        cd $D
    
        echo ptna-network.sh $*
    
        cd $WD
    fi
    
done



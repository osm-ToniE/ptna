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
    
        ptna-network.sh $*
    
        cd $WD
    fi
    
done



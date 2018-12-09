#!/bin/bash

#
# analyze ÖPNV networks
#


cd $PTNA_NETWORKS_LOC

WD=$PWD

for A in [A-Z]*
do
    if [ -d $A ]
    then
        echo
        echo $(date "+%Y-%m-%d %H:%M:%S") "$A"
        echo
    
        cd $A
    
        ptna-network.sh $*
    
        cd $WD
    fi
    
done



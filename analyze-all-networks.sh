#!/bin/bash

#
# analyze ÖPNV networks
#

WD=$PWD

PATH=$PWD/bin:$PATH

# day of week: 1 ... 7 (7 = Sunday)
DOW=$(date +%u)

for A in  Networks/*
do
    echo
    echo $(date "+%Y-%m-%d %H:%M:%S") "$A"
    echo
    
    ANALYZE="yes"
    
    NETWORK=$(basename $A)
    AREA=${NETWORK%%-*}
    
    if [ "$AREA" = "EU" -a $DOW -ne 7 ]
    then
        ANALYZE="no"
    fi
    
    if [ "$ANALYZE" = "yes" ]
    then
        cd $A
    
        analyze-network.sh $*
    
        cd $WD
    fi
    
done


#!/bin/bash

#
# analyze ÖPNV networks
#

WD=$PWD

PATH=$PWD/bin:$PATH

for A in  Networks/*
do
    echo
    echo $(date "+%Y-%m-%d %H:%M:%S") "$A"
    echo
    
    cd $A

    analyze-network.sh $*

    cd $WD

done


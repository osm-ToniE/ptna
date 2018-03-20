#!/bin/bash

#
# analyze ÖPNV networks
#

WD=$PWD

PATH=$PWD/bin:$PATH

for A in  Networks/*
do
    echo
    echo $A
    echo
    
    cd $A

    ./analyze-network.sh $1

    cd $WD

done


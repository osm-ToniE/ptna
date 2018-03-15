#!/bin/bash

#
# analyze ÖPNV routes
#

WD=$PWD

PATH=$PWD/bin:$PATH

for A in  Networks/*
do
    
    cd $A

    ./analyze-network.sh $1

    cd $WD

done


#!/bin/bash

#
# analyze ÖPNV routes
#

for A in  NETWORKS/*
do
    
    cd $A

    ./analyze-area.sh $1

    cd ..

done


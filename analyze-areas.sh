#!/bin/bash

#
# analyze ÖPNV routes
#

for A in  DE-BY-MVV DE-BY-RVO DE-BY-AVV DE-BY-INVG DE-NW-VRS
do
    
    cd $A

    ./analyze-area.sh $1

    cd ..

done


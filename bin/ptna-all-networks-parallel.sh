#!/bin/bash

#
# analyze ÖPNV networks
#

export PTNA_OVERPASS_API_SERVER="overpass.kumi.systems"

cd $PTNA_NETWORKS_LOC

find . -name settings.sh | \
sort                     | \
xargs -P6 -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'

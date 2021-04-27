#!/bin/bash

#
# analyze ÖPNV networks
#


cd $PTNA_NETWORKS_LOC

find . -name settings.sh | \
sort                     | \
xargs -P6 -I@ bash -c 'D=$(dirname @) && B=$(basename $D) && echo $(date "+%Y-%m-%d %H:%M:%S") $B && cd $D && ptna-network.sh '$*' > $PTNA_WORK_LOC/log/$B.log 2>&1'

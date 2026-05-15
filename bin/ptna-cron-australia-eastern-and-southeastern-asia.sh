#!/bin/bash

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "start: $(basename $0)"

# source $HOME/.ptna-config to overwrite the settings above
# and mybe to set some perl related variables (copied from .bashrc)

[ -f $HOME/.ptna-config ] && source $HOME/.ptna-config

# where can we find all the executables of PTNA

if [ -z "$PTNA_BIN" ]
then
    PTNA_BIN="$HOME/ptna/bin"
    export PATH="$PTNA_BIN:$HOME/bin:$PATH"
fi

# where can we find config files for osmium to split the planet file into pieces

PTNA_NETWORKS_LOC="${PTNA_NETWORKS_LOC:=/osm/ptna/ptna-networks}"

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:=/osm/ptna/work}"

###############################################################
#
# start working for UTC+10 UTC+09.30 UTC+08 UTC+07 - covers east and southeast Asia and Australia
#
###############################################################

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

if [ -f $PTNA_WORK_LOC/update-from-planet ]
then
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-asia.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-oceania.log
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-planet.sh UTC+10"
    ptna-handle-planet.sh UTC+10 > $PTNA_WORK_LOC/ptna-handle-planet-UTC+10.log 2>&1 < /dev/null
else
    # update from continent extracts from other server

    rm -f $PTNA_WORK_LOC/ptna-handle-planet-UTC+10.log

    # first time handling of ozeania, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh ozeania"
    ptna-handle-continent.sh ozeania > $PTNA_WORK_LOC/ptna-handle-continent-ozeania.log 2>&1 < /dev/null &

    # first time handling of asia, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh asia"
    ptna-handle-continent.sh asia    > $PTNA_WORK_LOC/ptna-handle-continent-asia.log    2>&1 < /dev/null &

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "wait for the 2 background jobs to finish"
    wait
fi

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

# when finished, start analysis of timezones (which include further extracts in e.g. UTC+01/*-osimium.config)

for utc in UTC+10 UTC+09.30 UTC+08 UTC+07
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-timezone.sh $utc"

    ptna-handle-timezone.sh $utc > $PTNA_WORK_LOC/ptna-handle-timezone-$utc.log 2>&1 < /dev/null
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "removing no longer needed '*.pbf'"
# asia-filtered.osm.pbf and oceania-filtered.osm.pbf may be deleted
for pbf in $(find $PTNA_WORK_LOC -name '*.osm.pbf' | grep -E -v 'africa|america|asia\.|europe|oceania\.|russia')
do
    #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "remove '$pbf', we don't need that any longer"
    rm -f "$pbf"
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "done: $(basename $0)"

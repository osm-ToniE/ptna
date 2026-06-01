#!/bin/bash

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "start: $(basename $0) $*"

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
# start working for UTC+03, UTC+02, UTC+01 and UTC+00 - covers Africa, Europe, Israel
#
###############################################################

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

if [ -f $PTNA_WORK_LOC/update-from-planet ]
then
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-africa.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-central-america.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-north-america.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-south-america.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-asia.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-europe.log
    rm -f $PTNA_WORK_LOC/ptna-handle-continent-oceania.log
    for utc in UTC+10 UTC+09.30 UTC+08 UTC+07 UTC+05.30 UTC+04 UTC+03.30 UTC+03 UTC+02 UTC+01 UTC+00 UTC-03 UTC-04 UTC-05 UTC-06 UTC-07 UTC-08 UTC-09
    do
        rm -f $PTNA_WORK_LOC/ptna-handle-timezone-$utc.log
        rm -f $PTNA_WORK_LOC/log/ptna-*-$utc.log
    done

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-planet.sh UTC-all"
    ptna-handle-planet.sh UTC-all > $PTNA_WORK_LOC/ptna-handle-planet-UTC-all.log 2>&1 < /dev/null
else
    # update from continent extracts from other server

    rm -f $PTNA_WORK_LOC/ptna-handle-planet-UTC-all.log

    # first time handling of africa, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh africa"
    ptna-handle-continent.sh africa > $PTNA_WORK_LOC/ptna-handle-continent-africa.log 2>&1 < /dev/null

    # first time handling of central america, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh central-america"
    ptna-handle-continent.sh central-america > $PTNA_WORK_LOC/ptna-handle-continent-central-america.log   2>&1 < /dev/null

    # first time handling of north america, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh north-america"
    ptna-handle-continent.sh north-america   > $PTNA_WORK_LOC/ptna-handle-continent-north-america.log     2>&1 < /dev/null

    # first time handling of south america, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh south-america"
    ptna-handle-continent.sh south-america   > $PTNA_WORK_LOC/ptna-handle-continent-south-america.log     2>&1 < /dev/null

    # first time handling of asia, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh asia"
    ptna-handle-continent.sh asia    > $PTNA_WORK_LOC/ptna-handle-continent-asia.log    2>&1 < /dev/null

    # first time handling of europe, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh europe"
    ptna-handle-continent.sh europe >  $PTNA_WORK_LOC/ptna-handle-continent-europe.log 2>&1 < /dev/null

    # first time handling of oceania, so overwrite log file
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh oceania"
    ptna-handle-continent.sh oceania > $PTNA_WORK_LOC/ptna-handle-continent-oceania.log 2>&1 < /dev/null

fi

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

# when finished, start analysis of timezones (which include further extracts in e.g. UTC+01/*-osimium.config)

for utc in UTC+10 UTC+09.30 UTC+08 UTC+07 UTC+05.30 UTC+04 UTC+03.30 UTC+03 UTC+02 UTC+01 UTC+00 UTC-03 UTC-04 UTC-05 UTC-06 UTC-07 UTC-08 UTC-09
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-timezone.sh $utc"

    ptna-handle-timezone.sh $utc > $PTNA_WORK_LOC/ptna-handle-timezone-$utc.log 2>&1 < /dev/null
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "removing no longer needed '*.pbf'"
# *-filtered.osm.pbf may be deleted
for pbf in $(find $PTNA_WORK_LOC -name '*.osm.pbf' | sort | grep -E -v 'planet\.|africa\.|america\.|asia\.|europe\.|oceania\.|russia\.')
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "remove '$pbf', we don't need that any longer"
    rm -f "$pbf"
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "done: $(basename $0)"

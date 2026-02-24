#!/bin/bash

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
# start working for UTC-07, UTC-08 and UTC-09 - covers western part of North America
#
###############################################################

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-cron-eastern-america.sh"

#echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-planet.sh UTC-07"
#ptna-handle-planet.sh UTC+03 > $PTNA_WORK_LOC/ptna-handle-planet-UTC-07.log 2>&1 < /dev/null

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

# second time handling of north america, so append to log file
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-continent.sh north-america"
ptna-handle-continent.sh europe >> $PTNA_WORK_LOC/ptna-handle-continent-north-america.log     2>>&1 < /dev/null &

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "wait for the background job to finish"
wait

# when finished, start analysis of timezones (which include further extracts in e.g. UTC-07/*-osimium.config)

for utc in UTC-07 UTC-08 UTC-09
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-timezone.sh $utc"

    ptna-handle-timezone.sh $utc > $PTNA_WORK_LOC/ptna-handle-timezone-$utc.log 2>&1 < /dev/null

done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "removing no longer needed '*.pbf'"
for pbf in $(find $PTNA_WORK_LOC -name '*.osm.pbf' | grep -E -v 'africa\.|america\.|asia\.|europe\.|oceania\.|russia\.')
do
    #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "remove '$pbf', we don't need that any longer"
    rm -f "$pbf"
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

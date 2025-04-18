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

PTNA_NETWORKS_LOC="${PTNA_NETWORKS_LOC:-/osm/ptna/ptna-networks}"

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:-/osm/ptna/work}"

###############################################################
#
# start working for UTC+03, UTC+02, UTC+01 and UTC+00 - covers Africa, Europe, Israel
#
###############################################################

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-planet.sh UTC+03"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

ptna-handle-planet.sh UTC+03 > $PTNA_WORK_LOC/ptna-handle-planet-UTC+03.log 2>&1 < /dev/null

# when finished, start analysis of timezones (which include further extracts in e.g. UTC+01/*-osimium.config)

for utc in UTC+03 UTC+02 UTC+01 UTC+00
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-handle-timezone.sh $utc"

    ptna-handle-timezone.sh $utc > $PTNA_WORK_LOC/ptna-handle-timezone-$utc.log 2>&1 < /dev/null

done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

for pbf in $(find $PTNA_WORK_LOC -name '*.osm.pbf' ! -name "planet.osm.pbf")
do
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "remove '$pbf', we don't need that any longer"
    rm -f "$pbf"
done

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

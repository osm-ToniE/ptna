#!/bin/bash

# This should happen below the $PTNA_WORK_LOC directory, where PTNA stores temporary files
# example for extracts for country 'germany'             : $PTNA_WORK_LOC/DE
# example for extracts for state   'bavaria' in 'germany': $PTNA_WORK_LOC/DE/BY

# should in be a file in the current DIR
# example for country 'germany'             : DE.osm.pbf    in $PTNA_WORK_LOC/DE
# example for state   'bavaria' in 'germany': DE-BY.osm.pbf in $PTNA_WORK_LOC/DE/BY
SOURCE="$1"

# shoud be the absolute path of the config file
# example for country 'germany'             : /osm/ptna/ptna-networks/UTC+01/DE/osmium.config
# example for state   'bavaria' in 'germany': /osm/ptna/ptna-networks/UTC+01/DE/BY/osmium.config
CONFIG="$2"

if [ -n "$SOURCE" - -f "$SOURCE" -a -s "$SOURCE" -a -n "$CONFIG" -a -f "$CONFIG" -a -s "$CONFIG" ]
then
    osmium extract --verbose --strategy=smart --config="$CONFIG" --overwrite --fsync "$SOURCE"

    extract_ret=$?

    exit $extract_ret
else
    echo $(date "+%Y-%m-%d %H:%M:%S") "There is no source file (1st parameter) and/or no config file (2nd parameter)"
    exit 1
fi

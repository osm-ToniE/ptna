#!/bin/bash

BASEURL="http://download.openstreetmap.fr/extracts"
SOURCE="europe/germany-latest.osm.pbf"
TARGET=germany.osm.pbf

CALL_PARAMS="--server-response --no-verbose"

wget $CALL_PARAMS --user-agent="PTNA script on https://ptna.openstreetmap.de" -O "$TARGET.part.$$" "$BASEURL/$SOURCE"

wget_ret=$?

fsize=$(stat -c '%s' $TARGET.part.$$)
if [ "$fsize" -gt 0 ]
then
    mv $TARGET.part.$$ $TARGET
    exit 0
else
    echo $(date "+%Y-%m-%d %H:%M:%S") "Failure for wget for '$TARGET' from '$BASEURL/$SOURCE'"
    exit 1
fi

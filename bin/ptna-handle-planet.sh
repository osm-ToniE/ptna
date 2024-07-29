#!/bin/bash

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:-/osm/ptna/work}"

BASEURL="https://planet.openstreetmap.org"
SOURCE="pbf/planet-latest.osm.pbf"
TARGET="planet.osm.pbf"

CALL_PARAMS="--server-response --no-verbose"


if [ -d "$PTNA_WORK_LOC" ]
then
    cd "$PTNA_WORK_LOC"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start handling planet file in '$PWD'"

    fsize=$(stat -c '%s' $TARGET)
    if [ ! -f "$TARGET" -o "$fsize" -lt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-get-extract.sh $BASEURL $SOURCE $TARGET"

        ptna-get-extract.sh "$BASEURL" "$SOURCE" "$TARGET"

        get_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-get-extract.sh returned $get_ret"
    fi

    fsize=$(stat -c '%s' $TARGET)
    if [ -f "$TARGET" -a "$fsize" -gt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-update-extract.sh $TARGET'"

        ptna-update-extract.sh "$TARGET"

        update_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-update-extract.sh returned $update_ret"
    fi

    fsize=$(stat -c '%s' $TARGET)
    if [ -f "$TARGET" -a "$fsize" -gt 4096 ]
    then
        FILTEREDTARGET="${TARGET%%.*}-filtered.osm.pbf"
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-filter-extract.sh $TARGET $FILTEREDTARGET'"

        ptna-filter-extract.sh "$TARGET" "$FILTEREDTARGET"

        filter_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-filter-extract.sh returned $filter_ret"

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$FILTEREDTARGET'"

        osmium fileinfo "$FILTEREDTARGET"

        osmium_ret=$?

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"
    fi

else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$PTNA_WORK_LOC' does not exist"
    exit 1
fi

exit 0

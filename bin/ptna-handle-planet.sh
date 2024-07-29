#!/bin/bash

# for which time zone?

PREPARE_FOR_TIMEZONE="$1"

# where can we find all the executables of PTNA

PTNA_BIN="${PTNA_BIN:-$HOME/ptna/bin}"
export PATH="$PTNA_BIN:$HOME/bin:$PATH"

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:-/osm/ptna/work}"

BASEURL="https://planet.openstreetmap.org"
SOURCE="pbf/planet-latest.osm.pbf"
TARGET="planet.osm.pbf"

if [ -d "$PTNA_WORK_LOC" ]
then
    cd "$PTNA_WORK_LOC"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start handling planet file in '$PWD'"

    if [ ! -f "$TARGET" -o $(stat -c '%s' $TARGET) -lt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-get-extract.sh $BASEURL $SOURCE $TARGET"

        ptna-get-extract.sh "$BASEURL" "$SOURCE" "$TARGET"

        get_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-get-extract.sh returned $get_ret"
    fi

    if [ -f "$TARGET" -a $(stat -c '%s' $TARGET) -gt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-update-extract.sh $TARGET'"

        ptna-update-extract.sh "$TARGET"

        update_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-update-extract.sh returned $update_ret"
    fi

    FILTEREDTARGET="${TARGET%%.*}-filtered.osm.pbf"
    if [ -f "$TARGET" -a $(stat -c '%s' $TARGET) -gt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-filter-extract.sh $TARGET $FILTEREDTARGET'"

        ptna-filter-extract.sh "$TARGET" "$FILTEREDTARGET"

        filter_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-filter-extract.sh returned $filter_ret"

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$FILTEREDTARGET'"

        osmium fileinfo "$FILTEREDTARGET"

        osmium_ret=$?

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"
    fi

    if [ -f "$FILTEREDTARGET" -a $(stat -c '%s' $FILTEREDTARGET) -gt 4096 ]
    then
        UTC_CONFIG="${TARGET%%.*}-$PREPARE_FOR_TIMEZONE-osmium.config"
        if [ -f "$UTC_CONFIG" -a -s "$UTC_CONFIG" ]
        then
            #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-split-extract.sh $FILTEREDTARGET $UTC_CONFIG'"

            ptna-split-extract.sh "$FILTEREDTARGET" "$UTC_CONFIG"

            split_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-split-extract.sh returned $split_ret"
        fi
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$PTNA_WORK_LOC' does not exist"
    exit 1
fi

exit 0

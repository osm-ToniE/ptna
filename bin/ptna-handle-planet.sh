#!/bin/bash

# for which time zone?

PREPARE_FOR_TIMEZONE="$1"

# source $HOME/.ptna-config to overwrite the settings above
# and mybe to set some perl related variables (copied from .bashrc)

[ -f $HOME/.ptna-config ] && source $HOME/.ptna-config

# where can we find all the executables of PTNA

if [ -z "$PTNA_BIN" ]
then
    PTNA_BIN="$HOME/ptna/bin"
    export PATH="$PTNA_BIN:$HOME/bin:$PATH"
fi

# we can we find config files for osmium to split the planet file into pieces

PTNA_NETWORKS_LOC="${PTNA_NETWORKS_LOC:-/osm/ptna/ptna-networks}"

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

    if [ -n "$PREPARE_FOR_TIMEZONE" ]
    then
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
            if [ -n "$PREPARE_FOR_TIMEZONE" ]
            then
                UTC_CONFIG="$PTNA_NETWORKS_LOC/${TARGET%%.*}-$PREPARE_FOR_TIMEZONE-osmium.config"
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Looking for osmium config file '$UTC_CONFIG'"

                if [ -f "$UTC_CONFIG" -a -s "$UTC_CONFIG" ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-split-extract.sh $FILTEREDTARGET $UTC_CONFIG'"

                    ptna-split-extract.sh "$FILTEREDTARGET" "$UTC_CONFIG"

                    split_ret=$?

                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-split-extract.sh returned $split_ret"

                    if [ $split_ret -eq 0 ]
                    then
                        rm -f "$FILTEREDTARGET"
                    fi
                fi
            fi
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "No preparation for a timezime, also no filtering of planet data"
        rm -f "$FILTEREDTARGET"
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$PTNA_WORK_LOC' does not exist"
    exit 1
fi

exit 0

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

# where can we find the planet file?

PLANET_LOC="${PLANET_LOC:=/osm/planetfile}"

# where can we find config files for osmium to split the planet file into pieces

PTNA_NETWORKS_LOC="${PTNA_NETWORKS_LOC:=/osm/ptna/ptna-networks}"

# we are working in PTNA_WORK_LOC

PTNA_WORK_LOC="${PTNA_WORK_LOC:=/osm/ptna/work}"

BASEURL="https://planet.openstreetmap.org"
SOURCE="pbf/planet-latest.osm.pbf"
PLANET="$PLANET_LOC/planet.osm.pbf"

if [ -d "$PLANET_LOC" -a -d "$PTNA_WORK_LOC" ]
then
    cd "$PTNA_WORK_LOC"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "start: $(basename $0) $* in '$PWD'"

    if [ ! -f "$PLANET" ]
    then
        # ensure, file exists
        touch $PLANET
    fi

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Planet file in '$PWD'"
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(ls -l $PLANET)"

    if [ ! -f "$PLANET" -o $(stat -c '%s' $PLANET) -lt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-get-extract.sh $BASEURL $SOURCE $PLANET"

        ptna-get-extract.sh "$BASEURL" "$SOURCE" "$PLANET"

        get_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-get-extract.sh returned $get_ret"
    fi

    if [ -f "$PLANET" -a $(stat -c '%s' $PLANET) -gt 4096 ]
    then
        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-update-extract.sh $PLANET'"

        ptna-update-extract.sh "$PLANET"

        update_ret=$?

        #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-update-extract.sh returned $update_ret"
    fi

    if [ -n "$PREPARE_FOR_TIMEZONE" ]
    then
        if [ -f "$PLANET" -a $(stat -c '%s' $PLANET) -gt 4096 ]
        then
            FILTERSOURCE="$PLANET"
            FILTERTARGET="$(basename $PLANET .osm.pbf)-filtered.osm.pbf"
            POSITIVEFILTER=$PTNA_NETWORKS_LOC/general-osmium-positive-filter.txt
            NEGATIVEFILTER=$PTNA_NETWORKS_LOC/general-osmium-negative-filter.txt
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-filter-extract.sh --positive $POSITIVEFILTER --negative $NEGATIVEFILTER --source $FILTERSOURCE --target $FILTERTARGET'"

            ptna-filter-extract.sh --positive "$POSITIVEFILTER" --negative "$NEGATIVEFILTER" --source "$FILTERSOURCE" --target "$FILTERTARGET"

            filter_ret=$?

            #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-filter-extract.sh returned $filter_ret"

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$FILTERTARGET'"

            osmium fileinfo "$FILTERTARGET"

            osmium_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"
        fi

        if [ -f "$FILTERTARGET" -a $(stat -c '%s' $FILTERTARGET) -gt 4096 ]
        then
            UTC_CONFIG="$PTNA_NETWORKS_LOC/${TARGET%%.*}-$PREPARE_FOR_TIMEZONE-osmium.config"
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Looking for osmium config file '$UTC_CONFIG'"

            if [ -f "$UTC_CONFIG" -a -s "$UTC_CONFIG" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-split-extract.sh $FILTERTARGET $UTC_CONFIG'"

                ptna-split-extract.sh "$FILTERTARGET" "$UTC_CONFIG"

                split_ret=$?

                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-split-extract.sh returned $split_ret"

                if [ $split_ret -eq 0 ]
                then
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "remove '$FILTERTARGET', we don't need that any longer"
                    rm -f "$FILTERTARGET"
                fi
            fi
        fi
    else
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "No preparation for a timezome, and no filtering of planet data"
        rm -f "$FILTERTARGET"
    fi

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "done: $(basename $0)"

else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$PTNA_WORK_LOC' does not exist"
    exit 1
fi

exit 0

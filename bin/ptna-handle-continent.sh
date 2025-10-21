#!/bin/bash

# for which sub-continent?

PREPARE_FOR_CONTINENT="$1"

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

BASEURL="https://download.openstreetmap.fr"
SOURCE="extracts/$PREPARE_FOR_CONTINENT.osm.pbf"
TARGET="$PREPARE_FOR_CONTINENT.osm.pbf"

if [ -d "$PTNA_WORK_LOC" ]
then
    cd "$PTNA_WORK_LOC"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start handling continent file 'PREPARE_FOR_CONTINENT' in '$PWD'"

    if [ ! -f "$TARGET" ]
    then
        get_it=yes
    else
        if [ $(stat -c '%s' $TARGET) -lt 4096 ]
        then
            get_it=yes
        fi
    fi

    if [ "$get_it" == "yes" ]
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
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-filter-extract.sh $TARGET $FILTEREDTARGET'"

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

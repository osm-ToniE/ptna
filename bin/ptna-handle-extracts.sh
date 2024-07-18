#!/bin/bash

# we are working in PTNA_WORK_DIR and further down
# NETWORKDIR is usually, when called from "ptna-all-networks-parallel.sh", something like "/osm/ptna/ptna-networks/UTC+01"
# we will recursively call this file here for sub-directories of the initial NETWORKDIR and also step downwards in the local dir

NETWORKDIR="$1"

echo $(date "+%Y-%m-%d %H:%M:%S") "Start handling planet extracts for '$NETWORKDIR' in '$PWD'"

if [ -f "$NETWORKDIR/extract-settings.sh" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "We have an 'extract-settings.sh' file in '$NETWORKDIR', 'source ...' it"
    source "$NETWORKDIR/extract-settings.sh"
    if [ -n "$BASEURL" -a -n "$SOURCE" -a -n "$TARGET" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S") "Check extract: from '$BASEURL/$SOURCE' for '$TARGET'"

        if [ ! -f "$TARGET" -o ! -s "$TARGET" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Call 'ptna-get-extract.sh $BASEURL $SOURCE $TARGET"

            ptna-get-extract.sh "$BASEURL" "$SOURCE" "$TARGET"

            get_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S") "ptna-get-extract.sh returned $get_ret"
        fi

        if [ -f "$TARGET" -a -s "$TARGET" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Call 'ptna-update-extract.sh $TARGET'"

            ptna-update-extract.sh "$TARGET"

            update_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S") "ptna-update-extract.sh returned $update_ret"
        fi


    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "Parameter(s) not set in '$NETWORKDIR/extract-settings.sh': BASEURL='$BASEURL', SOURCE='$SOURCE', TARGET='$TARGET'"
        exit 1
    fi
fi

if [ -f "$NETWORKDIR/osmium.config" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S") "We have an 'osmium.config' file in '$NETWORKDIR', do we have a '*.osm.pbf' in '$PWD'$?"
    # there should be only one *.osm.pbf file in this directory
    PBF_FILE=$(find . -mindepth 0 -maxdepth 1 -type f -name '*.osm.pbf')

    if [ -n "$PBF_FILE" -a -f "$PBF_FILE" -a -s "$PBF_FILE" ]
    then
            echo $(date "+%Y-%m-%d %H:%M:%S") "Call 'ptna-split-extract.sh $PBF_FILE $NETWORKDIR/osmium.config'"

            ptna-split-extract.sh "$PBF_FILE" "$NETWORKDIR/osmium.config"

            split_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S") "ptna-plit-extract.sh returned $split_ret"

    else
        echo $(date "+%Y-%m-%d %H:%M:%S") "No '*.osb.pbf' file ('$PBF_FILE') found in '$PWD' or the file is empty"
        exit 1
    fi
fi

for subdir in $(find . -mindepth 0 -maxdepth 1 -type d -name '[A-Z]*' | sort)
do
    pushd $subdir

    echo $(date "+%Y-%m-%d %H:%M:%S") "Calling 'ptna-handle-extracts.sh $NETWORKDIR/$subdir' in '$PWD'"

    ptna-handle-extracts.sh $NETWORKDIR/$subdir

    popd
done

echo $(date "+%Y-%m-%d %H:%M:%S") "End handling planet extracts for '$NETWORKDIR' in '$PWD'"

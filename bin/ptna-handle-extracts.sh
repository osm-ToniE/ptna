#!/bin/bash

# we are working in PTNA_WORK_LOC and further down
# NETWORKDIR is usually, when called from "ptna-all-networks-parallel.sh", something like "/osm/ptna/ptna-networks/UTC+01"
# we will recursively call this file here for sub-directories of the initial NETWORKDIR and also step downwards in the local dir

NETWORKDIR="${1%/}"

if [ -n "$NETWORKDIR" -a -d "$NETWORKDIR" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Start handling planet extracts for '$NETWORKDIR' in '$PWD'"

    for setting in $(find "$NETWORKDIR" -maxdepth 1 -type f -name '*-extract-settings.sh')
    do
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "We have '$setting' file, 'source ...' it"
        source "$setting"
        if [ -n "$BASEURL" -a -n "$SOURCE" -a -n "$TARGET" ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Check extract: from '$BASEURL/$SOURCE' for '$TARGET'"

            if [ ! -f "$TARGET" -o ! -s "$TARGET" ]
            then
                #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-get-extract.sh $BASEURL $SOURCE $TARGET"

                ptna-get-extract.sh "$BASEURL" "$SOURCE" "$TARGET"

                get_ret=$?

                #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-get-extract.sh returned $get_ret"
            fi

            if [ -f "$TARGET" -a -s "$TARGET" ]
            then
                #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-update-extract.sh $TARGET'"

                ptna-update-extract.sh "$TARGET"

                update_ret=$?

                #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-update-extract.sh returned $update_ret"
            fi


        else
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Parameter(s) not set in '$setting': BASEURL='$BASEURL', SOURCE='$SOURCE', TARGET='$TARGET'"
            exit 1
        fi
    done

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "find '$NETWORKDIR' -maxdepth 1 -type f -name '*-osmium.config' | sort"
    find "$NETWORKDIR" -maxdepth 1 -type f -name '*-osmium.config' | sort

    for config in $(find "$NETWORKDIR" -maxdepth 1 -type f -name '*-osmium.config' | sort)
    do
        PBF_FILE=$(basename ${config%-osmium.config}).osm.pbf

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "We have a '$config' file, looking for '$PBF_FILE' in '$PWD'?"

        if [ -n "$PBF_FILE" -a -f "$PBF_FILE" -a -s "$PBF_FILE" ]
        then
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'ptna-split-extract.sh $PBF_FILE $config'"

                # ensure directories for output files exist
                for of in $(jq -r ' .extracts[] | .output' "$config")
                do
                    [ -d $(dirname "$of") ] || mkdir -p $(dirname "$of")
                done

                ptna-split-extract.sh "$PBF_FILE" "$config"

                split_ret=$?

                #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "ptna-plit-extract.sh returned $split_ret"

        else
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$PBF_FILE' file not found in '$PWD' or the file is empty for '$config'"
            exit 1
        fi
    done

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "find '$NETWORKDIR' -mindepth 1 -maxdepth 1 -type d -name '[A-Z0-9]*' | sort"
    find "$NETWORKDIR" -mindepth 1 -maxdepth 1 -type d -name '[A-Z0-9]*' | sort

    for newdir in $(find "$NETWORKDIR" -mindepth 1 -maxdepth 1 -type d -name '[A-Z0-9]*' | sort)
    do
        subdir=$(basename $newdir)

        if [ -d "$subdir" ]
        then
            pushd $subdir > /dev/null

            #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Calling 'ptna-handle-extracts.sh $newdir' in '$PWD'"

            ptna-handle-extracts.sh $newdir

            popd > /dev/null
        fi
    done

    #echo $(date "+%Y-%m-%d %H:%M:%S %Z") "End handling planet extracts for '$NETWORKDIR' in '$PWD'"

else
    if [ -n "$NETWORKDIR" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'$NETWORKDIR' does not exist"
    else
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Please specify directory where to start the analysis"
    fi
    exit 1
fi

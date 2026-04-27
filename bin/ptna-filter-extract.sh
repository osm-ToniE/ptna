#!/bin/bash

TEMP=$(getopt -o n:p:s:t: --long negative:,positive:,source:,target: -n 'ptna-filter-extract.sh' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." ; exit 2 ; fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -n|--negative)  NEGATIVE_FILTER_FILE=$2                 ; shift 2 ;;
        -p|--positive)  POSITIVE_FILTER_FILE=$2                 ; shift 2 ;;
        -s|--source)    SOURCE=$2                               ; shift 2 ;;
        -t|--target)    TARGET=$2                               ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 3 ;;
    esac
done

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" -a -n "$TARGET" ]
then
    INPUTFORMAT="${SOURCE##*.}"
    OUTPUTFORMAT="${TARGET##*.}"

    if [ "$INPUTFORMAT" = "$OUTPUTFORMAT" ]
    then
        TMP1="${TARGET%.*}.$$-1.$INPUTFORMAT"
        TMP2="${TARGET%.*}.$$-2.$INPUTFORMAT"

        rm -f "$TMP1" "$TMP2"

        fsizes=$(stat -c '%s' "$SOURCE")

        if [ -n "$POSITIVE_FILTER_FILE" ]
        then
            if [ -f "$POSITIVE_FILTER_FILE" -a -r "$POSITIVE_FILTER_FILE" ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with positive filter list from file '$POSITIVE_FILTER_FILE'"
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"

                osmium tags-filter -v --expressions "$POSITIVE_FILTER_FILE" -F "$INPUTFORMAT" -f "$INPUTFORMAT" -O -o "$TMP1" "$SOURCE"

                osmium_ret=$?

                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"

                if [ $osmium_ret -eq 0 ]
                then
                    fsizep=$(stat -c '%s' "$TMP1")
                    if [ $fsizes -gt 0 ]
                    then
                        percentage=$(perl -e "printf('%.2f', $fsizep * 100 / $fsizes);")
                    else
                        percentage=0
                    fi
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "File sizes: source = '$fsizes', after positive filter = '$fsizep': $percentage %"
                else
                    TMP1="$SOURCE"
                fi
            else
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Positive filter list '$POSITIVE_FILTER_FILE' is not a file or cannot be read"
                exit 1
            fi
        else
            TMP1="$SOURCE"
        fi

        if [ -n "$NEGATIVE_FILTER_FILE" ]
        then
            if [ -f "$NEGATIVE_FILTER_FILE" -a -r "$NEGATIVE_FILTER_FILE" ]
            then
                if [ -f "$TMP1" -a -s "$TMP1" ]
                then

                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$TMP1' to filter with negative filter list from file '$NEGATIVE_FILTER_FILE'"
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"

                    osmium tags-filter -v -i --expressions "$NEGATIVE_FILTER_FILE" -F "$INPUTFORMAT" -f "$OUTPUTFORMAT" -O -o "$TMP2" "$TMP1"

                    osmium_ret=$?

                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"

                    if [ $osmium_ret -eq 0 ]
                    then
                        fsizen=$(stat -c '%s' "$TMP2")
                        if [ $fsizes -gt 0 ]
                        then
                            percentage=$(perl -e "printf('%.2f', $fsizen * 100 / $fsizes);")
                        else
                            percentage=0
                        fi
                        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "File sizes: source = '$fsizes', after negative filter = '$fsizen': $percentage %"
                    else
                        TMP2="$TMP1"
                    fi
                else
                    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filtered file (positive list) has not been created"
                    exit 1
                fi
            else
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Negative filter list '$NEGATIVE_FILTER_FILE' is not a file or cannot be read"
                exit 1
            fi
        else
            TMP2="$TMP1"
        fi

        cp "$TMP2" "$TARGET"

        rm -f "$TMP1" "$TMP2"

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$TARGET'"

        osmium fileinfo "$TARGET"

        fileinfo_ret=$?

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium fileinfo returned $fileinfo_ret"
    else
        echo "Format of source '$SOURCE' and target '$TARGET' files must be identical"
        exit 1
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "There is no source file and/or no target file specified or source file is empty"
    exit 1
fi

exit 0

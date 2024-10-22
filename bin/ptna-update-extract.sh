#!/bin/bash

SOURCE="$1"

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Update extract: call 'osmium fileinfo' for '$SOURCE'"

    osmium fileinfo $SOURCE

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    if [ $osmium_ret -eq 0 ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'pyosmium-up-to-date' for '$SOURCE'"
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

        pyosmium-up-to-date -v "$SOURCE"

        py_ret=$?

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "pyosmium returned $py_ret"
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df | grep 'osm')"

        if [ $py_ret -eq 0 ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$SOURCE'"

            osmium fileinfo "$SOURCE"

            osmium_ret=$?

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

            exit $osmium_ret
        else
            exit $py_ret
        fi
    else
        exit $osmium_ret
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "There is no source file (1st parameter)"
    exit 1
fi

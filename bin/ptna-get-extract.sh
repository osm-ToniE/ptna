#!/bin/bash

BASEURL="${1%/}"
SOURCE="$2"
TARGET="$3"

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Get extract: call wget for '$TARGET' from '$BASEURL/$SOURCE'"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df -h | grep 'osm')"

# create empty file, so that we can check size even if wget does not change the file at all

touch "$TARGET.part.$$"

wget --server-response --no-verbose --user-agent="PTNA script on https://ptna.openstreetmap.de" -O "$TARGET.part.$$" "$BASEURL/$SOURCE"

wget_ret=$?

echo $(date "+%Y-%m-%d %H:%M:%S %Z") "wget retuned $wget_ret"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(top -bn1 | grep -i '^.CPU')"
echo $(date "+%Y-%m-%d %H:%M:%S %Z") "$(df -h | grep 'osm')"

fsize=$(stat -c '%s' "$TARGET.part.$$")
if [ "$fsize" -gt 0 ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Overwriting '$TARGET' with new data: size $fsize bytes"
    mv "$TARGET.part.$$" "$TARGET"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$TARGET'"

    osmium fileinfo "$TARGET"

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    exit $osmium_ret
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Failure for wget for '$TARGET' from '$BASEURL/$SOURCE': no data retrieved"
    exit 1
fi

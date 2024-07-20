#!/bin/bash

SOURCE=$1
TARGET=$2

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" -a -n "$TARGET" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$SOURCE' to get replication timestamp"

    TS=$(osmium fileinfo "$SOURCE" | grep osmosis_replication_timestamp | head -1 | sed -e 's/^.*=//')

    rm -f "$TARGET-Data-filtered.osm.pbf"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with positive list"

    osmium tags-filter "$SOURCE" -v  -F pbf -f pbf -O -o "$TARGET-Data-filtered.osm.pbf" \
           r/type=*route r/type=public_transport r/type=network r/route_master r/route public_transport highway=bus_stop,platform railway=stop,tram_stop,halt,station,platform

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    if [ -f "$TARGET-Data-filtered.osm.pbf" -a -s "$TARGET-Data-filtered.osm.pbf" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with negative list"

        osmium tags-filter "$TARGET-Data-filtered.osm.pbf" -v -F pbf -f osm -O -o "$TARGET" \
               --output-header="generator=https://ptna.openstreetmap.de osmosis_replication_timestamp=$TS" \
               -i route=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,motorboat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding \
                  r/type=restriction landuse building natural shop office

        osmium_ret=$?

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

        rm -f "$TARGET-Data-filtered.osm.pbf"
    else
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filtered file (prositive list) has not been created or is empty"
        exit 1
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "There is no source file (1st parameter) and/or no target file specified (2nd parameter)"
    exit 1
fi

exit 0
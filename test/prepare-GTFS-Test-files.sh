#!/bin/bash

set -x


if [ ! -d GTFS/Test/files ]
then
    mkdir -p GTFS/Test/files
fi

if [ -d GTFS/Test/files ]
then

    pushd GTFS/Test/files

    ORG_DIR=~/Develop/OSM/gtfs-feeds/DE/BY/MVV
    DB="ptna-gtfs-sqlite.db"
    SQ_OPTIONS="-init /dev/null -batch -csv -header"
    SQ_OPTIONS_PURE="-init /dev/null -csv -batch -noheader"

    ru=$($ORG_DIR/get-release-url.sh)

    rm -f gtfs.zip *.txt ../osm.txt ../ptna.txt

    wget --no-verbose --read-timeout=60 --user-agent "PTNA script on https://ptna.openstreetmap.de" -O "gtfs.zip" "$ru"

    cp $ORG_DIR/osm.txt ../osm.txt

    cp $ORG_DIR/ptna.txt ../ptna.txt

    gtfs-prepare-ptna-sqlite.sh

    rm -f gtfs.zip *.txt ../osm.txt ../ptna.txt

    echo "" > ../osm.txt

    echo "" > ../ptna.txt

    sqlite3 $SQ_OPTIONS_PURE $DB "UPDATE feed_info SET feed_end_date='20361231';"

    sqlite3 $SQ_OPTIONS_PURE $DB "UPDATE calendar SET end_date='20361231';"

    sqlite3 $SQ_OPTIONS $DB "SELECT *                         FROM feed_info      ;" > feed_info.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT agency.*         FROM agency         JOIN routes ON routes.agency_id=agency.agency_id WHERE routes.route_short_name=210;" > agency.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT *                FROM routes         WHERE route_short_name=210;" > routes.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT trips.*          FROM trips          WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > trips.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT calendar.*       FROM calendar       JOIN trips on trips.service_id=calendar.service_id WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > calendar.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT calendar_dates.* FROM calendar_dates JOIN trips on trips.service_id=calendar_dates.service_id WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > calendar_dates.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT stops.*          FROM stops          JOIN stop_times ON stops.stop_id= stop_times.stop_id WHERE stop_times.trip_id IN (SELECT trip_id FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210)) ORDER BY stops.stop_name,stops.stop_id ASC;" > stops.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT *                FROM stop_times     WHERE trip_id IN (SELECT trip_id FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210));" > stop_times.txt

    sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT *                FROM shapes         WHERE shape_id IN (SELECT shape_id FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210));" > shapes.txt

    if [ ! -s shapes.txt ]
    then
        rm -f shapes.txt
    fi

    rm -f $DB

    popd

else
    echo "Cannot 'cd' into 'GTFS/Test/files'"
fi

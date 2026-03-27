#!/bin/bash

set -x

ORG_DIR=~/Develop/OSM/gtfs-feeds/DE/BY/MVV
DB="ptna-gtfs-sqlite.db"
SQ_OPTIONS="-init /dev/null -batch -csv -header"
SQ_OPTIONS_PURE="-init /dev/null -csv -batch -noheader"

ru=$($ORG_DIR/get-release-url.sh)

mkdir TEST

cd TEST

wget --no-verbose --read-timeout=60 --user-agent "PTNA script on https://ptna.openstreetmap.de" -O "gtfs.zip" "$ru"

rm *.txt

gtfs-prepare-ptna-sqlite.sh

rm *.txt


sqlite3 $SQ_OPTIONS_PURE $DB "UPDATE feed_info SET feed_end_date='20361231';"

sqlite3 $SQ_OPTIONS_PURE $DB "UPDATE calendar SET end_date='20361231';"

sqlite3 $SQ_OPTIONS $DB "SELECT * FROM feed_info;" > feed_info.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT agency.* FROM agency JOIN routes ON routes.agency_id=agency.agency_id WHERE routes.route_short_name=210;" > agency.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT * FROM routes WHERE route_short_name=210;" > routes.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT trips.* FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > trips.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT calendar.* FROM calendar JOIN trips on trips.service_id=calendar.service_id WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > calendar.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT calendar_dates.* FROM calendar_dates JOIN trips on trips.service_id=calendar_dates.service_id WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210);" > calendar_dates.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT stops.* from stops JOIN stop_times ON stops.stop_id= stop_times.stop_id WHERE stop_times.trip_id IN (SELECT trip_id FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210)) ORDER BY stops.stop_name,stops.stop_id ASC;" > stops.txt

sqlite3 $SQ_OPTIONS $DB "SELECT DISTINCT * from stop_times WHERE trip_id IN (SELECT trip_id FROM trips WHERE route_id IN (SELECT DISTINCT route_id FROM routes WHERE route_short_name=210));" > stop_times.txt

rm $DB

cd ..

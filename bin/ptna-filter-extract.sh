#!/bin/bash

SOURCE=$1
TARGET=$2

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" -a -n "$TARGET" ]
then
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filter extract: call 'osmium fileinfo' for '$SOURCE' to get replication timestamp"

    TS=$(osmium fileinfo "$SOURCE" | grep osmosis_replication_timestamp | head -1 | sed -e 's/^.*=//')

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'osmium replication timestamp' = '$TS'"

    rm -f "$TARGET-Data-filtered.osm.pbf"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with positive list"

    osmium tags-filter -v -F pbf -f pbf -O -o "$TARGET-Data-filtered.osm.pbf" "$SOURCE" \
           r/type=*route r/type=public_transport,network r/abandoned:type r/disused:type r/suspended:type r/razed:type r/removed:type r/route_master r/route r/network r/name r/ref r/from r/to r/via r/public_transport:version r/ref_trips \
           public_transport highway=bus_stop,platform railway=stop,tram_stop,halt,station,platform route_ref gtfs:feed gtfs:route_id gtfs:stop_id gtfs:trip_id gtfs:trip_id:sample gtfs:shape_id

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    if [ -f "$TARGET-Data-filtered.osm.pbf" -a -s "$TARGET-Data-filtered.osm.pbf" ]
    then
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with negative list"

        osmium tags-filter -v -F pbf -f osm -O -o "$TARGET" \
               --output-header="generator=https://ptna.openstreetmap.de osmosis_replication_timestamp=$TS" "$TARGET-Data-filtered.osm.pbf" \
               -i r/route_master=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction \
                  r/route=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction,canyoning,climbing,sled,TMC \
                  r/type=defaults,area,destination_sign,enforcement,person,treaty,cemetery,pipeline,election,level,restriction,boundary,building,waterway,building:part,organization,set,bridge,site,health,junction,right_of_way,dual_carriageway,street,associated_street,cluster,tunnel,tmc,TMC,tmc:point,tmc:area,traffic_signals,place_numbers,shop,group,collection \
                  r/type=*golf r/highway=pedestrian,service,living_street,footway r/network=lcn,rcn,ncn,icn,lwn,rwn,nwn,iwn,foot,bicycle,hiking \
                  indoor=room attraction area:highway aeroway cemetery historic power amenity boundary admin_level place tourism junction parking landuse landcover building roof:shape room natural shop office craft man_made leisure playground golf piste:type

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

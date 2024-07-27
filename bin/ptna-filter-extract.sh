#!/bin/bash

SOURCE=$1
TARGET=$2

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" -a -n "$TARGET" ]
then
    rm -f "$TARGET-[12].$$.osm.pbf"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with standard positive filter list"

    osmium tags-filter -v -F pbf -f pbf -O -o "$TARGET-1.$$.osm.pbf" "$SOURCE" \
           r/type=*route r/type=public_transport,network r/abandoned:type r/disused:type r/suspended:type r/razed:type r/removed:type r/route_master r/route r/network r/name r/ref r/from r/to r/via r/public_transport:version r/ref_trips \
           public_transport highway=bus_stop,platform railway=stop,tram_stop,halt,station,platform route_ref gtfs:feed gtfs:route_id gtfs:stop_id gtfs:trip_id gtfs:trip_id:sample gtfs:shape_id

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    if [ $osmium_ret -eq 0 -a -f "$TARGET-1.$$.osm.pbf" -a -s "$TARGET-1.$$.osm.pbf" ]
    then
        OUTPUTFORMAT="${TARGET##*.}"
        if [ "$OUTPUTFORMAT" == 'xml' ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filter extract: call 'osmium fileinfo' for '$SOURCE' to get replication timestamp"

            TS=$(osmium fileinfo "$SOURCE" | grep osmosis_replication_timestamp | head -1 | sed -e 's/^.*=//')

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'osmium replication timestamp' = '$TS'"

            OUTPUTHEADER='--output-header="generator=https://ptna.openstreetmap.de osmosis_replication_timestamp=$TS"'

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$TARGET-1.$$.osm.pbf' to filter with standard negative filter list (output format '$OUTPUTFORMAT')"

            osmium tags-filter -v -F pbf -f "$OUTPUTFORMAT" -O -o "$TARGET-2.$$.osm.$OUTPUTFORMAT" "$TARGET-1.$$.osm.pbf" \
                   --output-header="generator=https://ptna.openstreetmap.de osmosis_replication_timestamp=$TS" \
                   -i r/route_master=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction \
                       r/route=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction,canyoning,climbing,sled,TMC \
                       r/type=defaults,area,destination_sign,enforcement,person,treaty,cemetery,pipeline,election,level,restriction,boundary,building,waterway,building:part,organization,set,bridge,site,health,junction,right_of_way,dual_carriageway,street,associated_street,cluster,tunnel,tmc,TMC,tmc:point,tmc:area,traffic_signals,place_numbers,shop,group,collection \
                       r/type=*golf r/highway=pedestrian,service,living_street,footway r/network=lcn,rcn,ncn,icn,lwn,rwn,nwn,iwn,foot,bicycle,hiking \
                       indoor=room attraction area:highway aeroway cemetery historic power amenity boundary admin_level place tourism junction parking landuse landcover building roof:shape room natural shop office craft man_made leisure playground golf piste:type

            osmium_ret=$?
        else

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$TARGET-1.$$.osm.pbf' to filter with standard negative filter list (output format '$OUTPUTFORMAT')"

            osmium tags-filter -v -F pbf -f "$OUTPUTFORMAT" -O -o "$TARGET-2.$$.osm.$OUTPUTFORMAT" "$TARGET-1.$$.osm.pbf" \
                -i r/route_master=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction \
                    r/route=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction,canyoning,climbing,sled,TMC \
                    r/type=defaults,area,destination_sign,enforcement,person,treaty,cemetery,pipeline,election,level,restriction,boundary,building,waterway,building:part,organization,set,bridge,site,health,junction,right_of_way,dual_carriageway,street,associated_street,cluster,tunnel,tmc,TMC,tmc:point,tmc:area,traffic_signals,place_numbers,shop,group,collection \
                    r/type=*golf r/highway=pedestrian,service,living_street,footway r/network=lcn,rcn,ncn,icn,lwn,rwn,nwn,iwn,foot,bicycle,hiking \
                    indoor=room attraction area:highway aeroway cemetery historic power amenity boundary admin_level place tourism junction parking landuse landcover building roof:shape room natural shop office craft man_made leisure playground golf piste:type

            osmium_ret=$?
        fi

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

        if [ $osmium_ret -eq 0 ]
        then
            fsizep=$(stat -c '%s' "$SOURCE")
            fsize1=$(stat -c '%s' "$TARGET-1.$$.osm.pbf")
            fsize2=$(stat -c '%s' "$TARGET-2.$$.osm.pbf")

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "File sizes: source = '$fsizep', after positive filter = '$fsize1', target = '$fsize2'"

            mv "$TARGET-2.$$.osm.pbf" "$TARGET"

            rm -f "$TARGET-[12].$$.osm.pbf"

            if [ "$OUTPUTFORMAT" != 'xml' ]
            then
                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium fileinfo' for '$TARGET'"

                osmium fileinfo "$TARGET"

                fileinfo_ret=$?

                echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $fileinfo_ret"
            fi
        fi

        exit $osmium_ret
    else
        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filtered file (positive list) has not been created or is empty"
        exit 1
    fi
else
    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "There is no source file (1st parameter) and/or no target file specified (2nd parameter)"
    exit 1
fi

exit 0

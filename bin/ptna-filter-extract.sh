#!/bin/bash

SOURCE=$1
TARGET=$2

if [ -n "$SOURCE" -a -f "$SOURCE" -a -s "$SOURCE" -a -n "$TARGET" ]
then
    INPUTFORMAT="${SOURCE##*.}"
    OUTPUTFORMAT="${TARGET##*.}"
    TMP1="${TARGET%.*}.$$-1.$INPUTFORMAT"
    TMP2="${TARGET%.*}.$$-2.$OUTPUTFORMAT"

    rm -f "$TMP1" "$TMP2"

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$SOURCE' to filter with standard positive filter list"

    osmium tags-filter -v -F "$INPUTFORMAT" -f "$INPUTFORMAT" -O -o "$TMP1" "$SOURCE" \
           r/type=*route r/type=public_transport,network r/proposed:type r/planned:type r/construction:type r/ruins:type r/demolished:type r/destroyed:type r/abandoned:type r/disused:type r/suspended:type r/razed:type r/removed:type r/was:type \
           r/route_master r/proposed:route_master r/planned:route_master r/construction:route_master r/ruins:route_master r/demolished:route_master r/destroyed:route_master r/abandoned:route_master r/disused:route_master r/suspended:route_master r/razed:route_master r/removed:route_master r/was:route_master \
           r/route r/proposed:route r/planned:route r/construction:route r/ruins:route r/demolished:route r/destroyed:route r/abandoned:route r/disused:route r/suspended:route r/razed:route r/removed:route r/was:route \
           r/network r/name r/ref r/from r/to r/via r/public_transport:version r/ref_trips \
           public_transport highway=bus_stop,platform railway=stop,tram_stop,halt,station,platform route_ref gtfs:feed gtfs:route_id gtfs:stop_id gtfs:trip_id gtfs:trip_id:sample gtfs:shape_id

    osmium_ret=$?

    echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

    if [ $osmium_ret -eq 0 -a -f "$TMP1" -a -s "$TMP1" ]
    then
        if [ "$OUTPUTFORMAT" == 'xml' ]
        then
            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Filter extract: call 'osmium fileinfo' for '$SOURCE' to get replication timestamp"

            TS=$(osmium fileinfo "$SOURCE" | grep osmosis_replication_timestamp | head -1 | sed -e 's/^.*=//')

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "'osmium replication timestamp' = '$TS'"

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$TMP1' to filter with standard negative filter list (output format '$OUTPUTFORMAT')"

            osmium tags-filter -v -F "$INPUTFORMAT" -f "$OUTPUTFORMAT" -O -o "$TMP2" "$TMP1" \
                   --output-header="generator=https://ptna.openstreetmap.de osmosis_replication_timestamp=$TS" \
                   -i r/route_master=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction \
                      r/route=tracks,railway,bicycle,mtb,hiking,road,foot,inline_skates,canoe,detour,fitness_trail,horse,waterway,motorboat,boat,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction,canyoning,climbing,sled,TMC \
                      r/type=defaults,area,destination_sign,enforcement,person,treaty,cemetery,pipeline,election,level,restriction,boundary,building,waterway,building:part,organization,set,bridge,site,health,junction,right_of_way,dual_carriageway,street,associated_street,cluster,tunnel,tmc,TMC,tmc:point,tmc:area,traffic_signals,place_numbers,shop,group,collection \
                      r/type=*golf r/highway=pedestrian,service,living_street,footway r/network=lcn,rcn,ncn,icn,lwn,rwn,nwn,iwn,foot,bicycle,hiking \
                      n/highway=stop,give_way,street_lamp,crossing,traffic_signals n/emergency=fire_hydrant,assemply_point,emergency_access_point indoor=room attraction area:highway aeroway cemetery historic power amenity boundary admin_level place tourism junction parking landuse landcover building roof:shape room natural shop sport telecom office craft leisure playground golf piste:type  healthcare geological \
                      wikidata=Q55085720 heritage


            osmium_ret=$?
        else

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "Call 'osmium tags-filter' for '$TMP1' to filter with standard negative filter list (output format '$OUTPUTFORMAT')"

            osmium tags-filter -v -F "$INPUTFORMAT" -f "$OUTPUTFORMAT" -O -o "$TMP2" "$TMP1" \
                   -i r/route_master=tracks,railway,bicycle,mtb,hiking,road,foot,walking,inline_skates,canoe,detour,alpine_coaster,fitness_trail,horse,waterway,motorboat,boat,worship,roller_coaster,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction \
                      r/route=tracks,railway,bicycle,mtb,hiking,road,foot,walking,inline_skates,canoe,detour,alpine_coaster,fitness_trail,horse,waterway,motorboat,boat,worship,roller_coaster,nordic_walking,pipeline,piste,power,running,ski,snowmobile,cycling,historic,motorcycle,riding,junction,canyoning,climbing,sled,TMC \
                      r/type=defaults,area,destination_sign,enforcement,person,treaty,cemetery,pipeline,election,level,restriction,boundary,building,waterway,building:part,organization,set,bridge,site,health,junction,right_of_way,dual_carriageway,street,associated_street,cluster,tunnel,tmc,TMC,tmc:point,tmc:area,traffic_signals,place_numbers,shop,group,collection,power \
                      r/route_master=*historic r/route=*historic r/type=*golf r/type=*whitewater r/highway=pedestrian,service,living_street,footway r/network=lcn,rcn,ncn,icn,lwn,rwn,nwn,iwn,foot,bicycle,hiking,waterway \
                      n/highway=stop,give_way,street_lamp,crossing,traffic_signals ra/highway=rest_area,services n/emergency=fire_hydrant,assemply_point,emergency_access_point indoor=room attraction area:highway aeroway cemetery historic power amenity boundary admin_level place tourism junction parking pipeline landuse landcover building roof:shape room natural shop sport telecom office craft leisure playground golf piste:type healthcare geological \
                      wikidata=Q55085720 heritage

            osmium_ret=$?
        fi

        echo $(date "+%Y-%m-%d %H:%M:%S %Z") "osmium returned $osmium_ret"

        if [ $osmium_ret -eq 0 ]
        then
            fsizep=$(stat -c '%s' "$SOURCE")
            fsize1=$(stat -c '%s' "$TMP1")
            fsize2=$(stat -c '%s' "$TMP2")

            echo $(date "+%Y-%m-%d %H:%M:%S %Z") "File sizes: source = '$fsizep', after positive filter = '$fsize1', after negative filter (=target) = '$fsize2'"

            mv "$TMP2" "$TARGET"

            rm -f "$TMP1" "$TMP2"

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

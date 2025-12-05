#!/bin/bash

NETWORK="$1"

if [ -n "$NETWORK" ]
then
    DETAILS_FILE=$(find $PTNA_WORK_LOC -name "$NETWORK-Analysis-details.txt")

    if [ -n "$DETAILS_FILE" -a -f "$DETAILS_FILE" -a -r "$DETAILS_FILE" ]
    then
        SEARCH_AREA=$(grep -F OVERPASS_SEARCH_AREA=area $DETAILS_FILE | sed -e 's/.*AREA=area//')

        if [ -n "$SEARCH_AREA" ]
        then
            URI_ENCODED=$(echo "relation$SEARCH_AREA;out ids;" | sed -e 's/ /%20/g' -e 's/"/%22/g' -e 's/\$/%24/g' -e 's/&/%26/g' -e "s/'/%27/g" -e 's/(/%28/g' -e 's/)/%29/g' -e 's/;/%3B/g' -e 's/=/%3D/g' -e 's/\?/%3F/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g' -e 's/\^/%5E/g' -e 's/|/%7C/g' -e 's/~/%7E/g')

            IDS=$(curl -s "https://overpass-api.de/api/interpreter?data=$URI_ENCODED" | grep -F "relation id=" | sed -e 's/.*relation id="//' -e 's/".*$//')

            for id in $IDS
            do
                curl -s "https://polygons.openstreetmap.fr/get_poly.py?id=$id&params=0.02000-0.00500-0.00500" > $HOME/tmp/$NETWORK-$id.poly
            done
        else
            echo "Search area not found"
        fi
    else
        echo "Details file not found"
    fi
fi

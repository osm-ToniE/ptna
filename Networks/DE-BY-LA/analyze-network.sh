#!/bin/bash

#
# analyze ÖPNV routes
#

if [ "$1" = "-w" ]
then
    call_wget="yes"
fi

PREFIX="DE-BY-LA"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'Landshut']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Landshuter Regionalbusnetz"
NETWORK_SHORT="LA"

CSV_FILE="$PREFIX-Routes.txt"
XML_FILE="$PREFIX-Data.xml"
WIKI_FILE="$PREFIX-Analysis.wiki"
HTML_FILE="$PREFIX-Analysis.html"

#
# 
#

if [ -f $WIKI_FILE ]
then
    mv $WIKI_FILE $WIKI_FILE.save
    rm -f $WIKI_FILE.diff
fi

if [ "$call_wget" = "yes" ]
then
    wget "$OVERPASS_QUERY" -O $XML_FILE
fi

# --check-bus-stop 
# 

analyze-routes.pl -v --wiki --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --positive-notes --coloured-sketchline --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --lines-csv=$CSV_FILE --routes=$XML_FILE > $WIKI_FILE

if [ -f $WIKI_FILE.save ]
then
    diff $WIKI_FILE $WIKI_FILE.save                                 | \
    sed -e 's/ <small>([^)]*)<\/small>//g'                          | \
    sed -e 's/{{Relation|//g'                                       | \
    sed -e 's/\[\[Image:Osm_element_relation.svg|20px\]\]//g'       | \
    sed -e 's/\[\[Image:Osm_element_way.svg|20px\]\]//g'            | \
    sed -e 's/\[\[Image:Osm_element_node.svg|20px\]\]//g'           | \
    sed -e 's/\[http:..osm.org.relation.[0-9]* //g'                 | \
    sed -e 's/\[http:..osm.org.way.[0-9]* //g'                      | \
    sed -e 's/\[http:..osm.org.node.[0-9]* //g'                     | \
    sed -e 's/\], //g'                                              | \
    sed -e 's/\]//g'                                                | \
    sed -e 's/}}//g'                                                > $WIKI_FILE.diff
fi


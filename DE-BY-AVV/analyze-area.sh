#!/bin/bash

#
# analyze ÖPNV routes
#

if [ "$1" = "-w" ]
then
    call_wget="yes"
fi

PREFIX="DE-BY-AVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=rel(poly:'48.61770452697 11.02169002533 48.58501115626 11.19953121185 48.46973480351 11.25617946625 48.21254898969 11.12709011078 48.17799160114 10.92555965424 48.10009492726 10.7775875473 48.12828883981 10.53657497406 48.44036225231 10.51700557709 48.55706881063 10.59871639252 48.66761187551 10.78685726166 48.66738513564 10.85140193939 48.61611575521 10.86376155853')[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Augsburger Verkehrs- und Tarifverbund"
NETWORK_SHORT="AVV"

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

../analyze-routes.pl -v --wiki --check-access --check-name --check-stop-position --check-sequence --check-version --positive-notes --coloured-sketchline --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --lines-csv=$CSV_FILE --routes=$XML_FILE > $WIKI_FILE
#../analyze-routes.pl -v        --positive-notes --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --lines-csv=$CSV_FILE --routes=$XML_FILE > $HTML_FILE 

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


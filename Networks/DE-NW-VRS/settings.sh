#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-NW-VRS"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Rhein-Sieg']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsverbund Rhein-Sieg|NRW Regionalverkehr"
NETWORK_SHORT="VRS"

WIKI_ANALYSIS_PAGE="VRS/Analyse"
WIKI_ROUTES_PAGE="VRS/Analyse/VRS-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-wide-characters --relaxed-begin-end-for='train,light_rail,tram_ --coloured-sketchline --expect-network-long --expect-network-short-for='Verkehrsverbund Rhein-Sieg' --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --lines-csv=$CSV_FILE --routes=$XML_FILE"

# --positive-notes
# --check-bus-stop 
# --expect-network-short
# --expect-network-long-for=


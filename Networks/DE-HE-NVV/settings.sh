#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-HE-NVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'(Kassel|Werra-Meißner-Kreis|Schwalm-Eder-Kreis|Waldeck-Frankenberg|Hersfeld-Rotenburg)']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Nordhessischer VerkehrsVerbund"
NETWORK_SHORT="NVV"

WIKI_ANALYSIS_PAGE="Kassel/Transportation/Analyse"
WIKI_ROUTES_PAGE="Kassel/Transportation/Analyse/DE-HE-NVV-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="--v --wiki --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --positive-notes --coloured-sketchline --expect-network-long --network-long-regex="$NETWORK_LONG" --network-short-regex="$NETWORK_SHORT" --lines-csv=$CSV_FILE --routes=$XML_FILE"

# --max-error=
# --check-bus-stop 
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-LA"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'Landshut']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Landshuter Regionalbusnetz"
NETWORK_SHORT="LA"

WIKI_ANALYSIS_PAGE="Landshut/Transportation/Analyse"
WIKI_ROUTES_PAGE="Landshut/Transportation/Analyse/DE-BY-LA-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --max-error=
# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


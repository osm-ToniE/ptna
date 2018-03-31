#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-RVV"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'Regensburg']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Regensburger Verkehrsverbund"
NETWORK_SHORT="RVV"

WIKI_ANALYSIS_PAGE="Regensburg/Transportation/Analyse"
WIKI_ROUTES_PAGE="Regensburg/Transportation/Analyse/DE-BY-RVV-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


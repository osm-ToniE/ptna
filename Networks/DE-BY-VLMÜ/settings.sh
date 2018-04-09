#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-VLMÜ"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name='Landkreis Mühldorf am Inn']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsgemeinschaft Landkreis Mühldorf"
NETWORK_SHORT="VLMÜ"

WIKI_ANALYSIS_PAGE="Mühldorf/Transportation/Analyse"
WIKI_ROUTES_PAGE="Mühldorf/Transportation/Analyse/DE-BY-VLMÜ-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


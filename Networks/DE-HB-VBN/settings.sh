#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-HB-VBN"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Bremen/Niedersachsen']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsverbund Bremen/Niedersachsen"
NETWORK_SHORT="VBN"

WIKI_ANALYSIS_PAGE="Bremen/Transport/Analyse"
WIKI_ROUTES_PAGE="Bremen/Transport/Analyse/DE-HB-VBN-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --positive-notes --check-access --check-name --check-stop-position --check-sequence --check-version --check-wide-characters --multiple-ref-type-entries=analyze --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


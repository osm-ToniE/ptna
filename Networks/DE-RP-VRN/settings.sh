#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-RP-VRN"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Rhein-Neckar']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsverbund Rhein-Neckar"
NETWORK_SHORT="VRN"

ANALYSIS_PAGE="Verkehrsverbund_Rhein-Neckar/Analyse"
WIKI_ROUTES_PAGE="Verkehrsverbund_Rhein-Neckar/Analyse/DE-RP-VRN-Linien"
FILE_DIFF="196"

ANALYSIS_OPTIONS="--max-error=10 --check-access --check-stop-position --check-sequence --check-wide-characters --positive-notes --check-name --multiple-ref-type-entries=analyze --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=
# 

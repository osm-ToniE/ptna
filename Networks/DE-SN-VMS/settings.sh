#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-SN-VMS"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Mittelsachsen']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsverbund Mittelsachsen"
NETWORK_SHORT="VMS"

WIKI_ANALYSIS_PAGE="Saxony/Transportation/Verkehrsverbund_Mittelsachsen/Analyse"
WIKI_ROUTES_PAGE="Saxony/Transportation/Verkehrsverbund_Mittelsachsen/Analyse/DE-SN-VMS-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --positive-notes --check-access --check-name --check-stop-position --check-sequence --check-wide-characters --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


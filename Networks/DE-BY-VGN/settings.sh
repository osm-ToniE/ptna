#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-VGN"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Großraum Nürnberg GmbH']->.L; rel(area.L)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)']->.R; rel(br.R); out; rel.R; out; rel(r.R); out; way(r.R); out; node(r.R); out;"
NETWORK_LONG="Verkehrsverbund Großraum Nürnberg"
NETWORK_SHORT="VGN"

WIKI_ANALYSIS_PAGE="Nürnberg/Transportation/Analyse"
WIKI_ROUTES_PAGE="Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien"
WIKI_FILE_DIFF="196"

ANALYSIS_OPTIONS="-v --wiki --max-error=10 --check-sequence --check-access --check-name --check-stop-position --check-version --check-wide-characters --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for= 


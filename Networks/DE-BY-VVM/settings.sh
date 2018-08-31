#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-VVM"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=administrative][admin_level=6][name~'(Landkreis Günzburg|Landkreis Unterallgäu)'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Verkehrsverbund Mittelschwaben"
NETWORK_SHORT="VVM"

ANALYSIS_PAGE="Mittelschwaben/Transportation/Analyse"
WIKI_ROUTES_PAGE="Mittelschwaben/Transportation/VVM-Linien-gesamt"

ANALYSIS_OPTIONS="--max-error=10 --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=allow --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=

#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-HB-VBN"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Bremen/Niedersachsen'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Verkehrsverbund Bremen/Niedersachsen"
NETWORK_SHORT="VBN"

ANALYSIS_PAGE="Bremen/Transport/Analyse"
WIKI_ROUTES_PAGE="Bremen/Transport/Analyse/DE-HB-VBN-Linien"

ANALYSIS_OPTIONS="--max-error=10 --positive-notes --check-access --check-name --check-stop-position --check-sequence --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=analyze --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for=


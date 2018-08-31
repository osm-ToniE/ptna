#!/bin/bash

#
# set variales for analysis of network
#

PREFIX="DE-BY-VGN"

OVERPASS_QUERY="http://overpass-api.de/api/interpreter?data=area[boundary=public_transport][name='Verkehrsverbund Großraum Nürnberg GmbH'];(rel(area)[route~'(bus|tram|train|subway|light_rail|trolleybus|ferry|monorail|aerialway|share_taxi|funicular)'];rel(br);rel[type='route'](r);)->.routes;(.routes;<<;rel(r.routes);way(r.routes);node(r.routes););out;"
NETWORK_LONG="Verkehrsverbund Großraum Nürnberg"
NETWORK_SHORT="VGN"

ANALYSIS_PAGE="Nürnberg/Transportation/Analyse"
WIKI_ROUTES_PAGE="Nürnberg/Transportation/Analyse/DE-BY-VGN-Linien"

ANALYSIS_OPTIONS="--max-error=10 --check-sequence --check-access --check-name --check-stop-position --check-version --check-osm-separator --check-motorway-link --multiple-ref-type-entries=analyze --positive-notes --coloured-sketchline"

# --check-bus-stop 
# --expect-network-long
# --expect-network-short
# --expect-network-short-for=
# --expect-network-long-for=
# --relaxed-begin-end-for= 

